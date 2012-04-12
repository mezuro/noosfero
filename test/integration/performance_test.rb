require "#{File.dirname(__FILE__)}/../test_helper"
require 'benchmark'

class PerformanceTest < ActionController::IntegrationTest

  all_fixtures

  FACTOR = 1.8

  # Testing blog page display. It should not present a linear increase in time
  # needed to display a blog page with the increase in number of posts.
  #
  # GOOD          BAD
  #
  # ^             ^     /
  # |             |    /
  # |   _____     |   /
  # |  /          |  /
  # | /           | /
  # |/            |/
  # +--------->   +--------->
  # 0  50  100    0  50  100
  #
  should 'not have a linear increase in time to display a blog page' do
    person = create_profile('clueless')

    person0 = create_profile('person0')
    person1 = create_profile('person1')
    create_posts(person1, 50)
    person2 = create_profile('person2')
    create_posts(person2, 100)

    get '/person0/blog'
    get '/person1/blog'
    get '/person2/blog'

    # no posts
    time0 = (Benchmark.measure { 10.times { get '/person0/blog' } })

    # first 50
    time1 = (Benchmark.measure { 10.times { get '/person1/blog' } })

    # another 50
    time2 = (Benchmark.measure { 10.times { get '/person2/blog' } })

    # should not scale linearly, i.e. the inclination of the first segment must
    # be a lot higher than the one of the segment segment. To compensate for
    # small variations due to hardware and/or execution environment, we are
    # satisfied if the the inclination of the first segment is at least twice
    # the inclination of the second segment.
    a1 = (time1.total - time0.total)/50.0
    a2 = (time2.total - time1.total)/50.0
    assert a1 > a2*FACTOR, "#{a1} should be larger than #{a2} by at least a factor of #{FACTOR}"
  end

  should 'not have a linear increase in time to save enterprise due to amount of products' do
    enterprise0 = Enterprise.create!(:name => 'Enterprise 0', :identifier => 'enterprise0')
    enterprise1 = Enterprise.create!(:name => 'Enterprise 1', :identifier => 'enterprise1')
    enterprise2 = Enterprise.create!(:name => 'Enterprise 2', :identifier => 'enterprise2')

    create_products(enterprise1,25)
    create_products(enterprise2,50)

    enterprise0.reload
    enterprise1.reload
    enterprise2.reload

    time0 = (Benchmark.measure { 10.times { enterprise0.save! } }).total
    time1 = (Benchmark.measure { 10.times { enterprise1.save! } }).total
    time2 = (Benchmark.measure { 10.times { enterprise2.save! } }).total

    assert (time1 - time0) < time0*0.5
    assert (time2 - time0) < time0*0.5
  end

  protected

  def create_profile(name)
    person = create_user(name).person
    Blog.create(:name => "Blog", :profile => person)
    person
  end

  def create_posts(profile, n)
    postnumber = profile.articles.count
    blog = profile.blog
    n.times do |i|
      postnumber += 1
      TinyMceArticle.create!(:profile => profile, :parent => blog, :name => "post number #{postnumber}")
    end
  end

  def create_products(enterprise,n)
    number = Product.all.count
    pc = ProductCategory.create!(:name => "Any Category #{n}", :environment => Environment.default)
    n.times do |i|
      Product.create!(:enterprise => enterprise, :product_category => pc, :name => "Product #{i+number+1}")
    end
  end

end

