require 'test_helper'
require 'parsers/company'
require 'utils/classifier'
require 'parsers/city'

class PostTest < ActiveSupport::TestCase

  def setup
    classifier = Classifier.new
    classifier.train("hiring", "lib/files/whoishiring.txt")
    @company_parser = Company.new(classifier)
    @city_parser = City.new
  end

  def teardown
    @company_parser = nil
  end

  test "all city regular expressions should be non-nil" do
    patterns = @city_parser.get_full_matchers
    patterns.each do |pattern|
      assert_not_equal(pattern, nil)
    end
  end

  test "full pattern regular expressions should be well formed" do
    patterns = @city_parser.get_full_matchers
    one_match = false 
    match_string = "Hey we're a shop out of San Francisco, California"
    patterns.each do |pattern|
      if pattern.match(match_string)
        one_match = true
      end
    end
    assert(one_match)
  end

  test "partial pattern regular expressions should be well formed" do
    patterns = @city_parser.get_abbrev_matchers
    one_match = false
    match_string = "Hey we're a shop out of San Francisco, CA bro"
    patterns.each do |pattern|
      if pattern.match(match_string)
        one_match = true
      end
    end
    assert(one_match)
  end

  test "should recognize full url company names" do
    post_content = "Helsinki, Finland - Blaast (<a href=\"http://blaast.com\" rel=\"nofollow\">http://blaast.com</a>)<p>Rocking mobile -- making it fun and accessible for millions of users and thousands of new developers.<p>Looking for various positions, from platform/backend, to operations, frontend and developer tools. We work with Scala, Java and Javascript. We are lean and fast. We deploy multiple times per day.<p><a href=\"http://blaast.com/jobs\" rel=\"nofollow\">http://blaast.com/jobs</a>"
    
    post_urls = ["http://blaast.com", "http://blaast.com/jobs"]

    assert_equal(@company_parser.parse(post_content, post_urls), "Blaast", "Company name is directly in the URL")
  end

  test "should keep original capitalization of full url company names" do
    post_content = "San Francisco, CA<p>SeatMe is hiring! We're a cozy 13 person startup in downtown San Francisco. We're revolutionizing the restaurant industry and we need your help! We're in search of:<p><pre><code>  * Web developers (we're a Django/jQuery/Backbone shop) </code></pre> How often do you get a chance to work at a tech startup where eating out can be written off as a tax-refundable business expense? Well not here, because our CEO would go to jail (and he's never going back to the big house), but we do work in an awesome intersection of technology and fine dining.<p>We offer a very competitive salary, benefits, moving costs and equity options for all full-time employees.<p>Apply online - <a href=\"http://www.seatme.com/jobs/\" rel=\"nofollow\">http://www.seatme.com/jobs/</a><p>Questions - jobs@seatme.com"
    post_urls = ["http://www.seatme.com/jobs/"]

    assert_equal(@company_parser.parse(post_content, post_urls), "SeatMe", "Company name capitalization does not match")
  end

  test "should recognize full url company names which use tld in name" do
    post_content = "New York, NY - Software Engineer - Fulltime<p>Canvas (USV Funded) is looking for engineers #3 and #4 to join a small close team building the rich-media community platform of the future.<p>The job title says \"Software Engineer\" but really we're looking for \"Software Entrepreneur\" or a \"Startup Engineer\". Yes, your day job will be writing code. But that's the only similarity to a big company software job.<p>You'll be challenged to take big ideas and turn them into concrete testable hypotheses. Shipping a great feature is important, but positively changing user behavior is the ultimate success criteria. Built-to-spec takes a backseat to moves-the-metrics.<p>More details and how to apply <a href=\"http://canv.as/jobs\" rel=\"nofollow\">http://canv.as/jobs</a>"
    post_urls = ['http://canv.as/jobs']
    
    assert_equal(@company_parser.parse(post_content, post_urls), "Canvas", "Company name is directly in the URL+TLD")
  end

  test "another should recognize full url company names which use tld in name" do
    post_content = "Amsterdam, Netherlands. Both INTERN and full-time positions.<p>We launched Skylines last may at Techcrunch Disrupt, our mission is to organize the world's real time photos. We currently process over two million pictures a day, are ramping up quickly, and generate a lot of data in the process. We're looking for people who can help us scale and analyze this data. Mostly backend developers on various technologies, ranging from Riak, Ruby and Map-Reduce to PHP, MySQL and Redis. We're based in the center of beautiful Amsterdam in an active startup community. Current alpha product at <a href=\"http://skylin.es\" rel=\"nofollow\">http://skylin.es</a>.<p>Questions? Shoot me an email at martijn@skylin.es."
    post_urls = ["http://skylin.es"]

    assert_equal(@company_parser.parse(post_content, post_urls), "Skylines", "Company name is directly in the URL+TLD")
  end

  test "should recognize full url company names which use tld and dot in name" do
    post_content = "San Francisco, CA Visual.ly<p>We are small and nimble team building a consumer-friendly data visualization tool and are looking for few front-end hackers with demonstrated expertise in all or many of the following and a passion for data visualization to round out our core engineering team.<p>* Javascript, Backbone.js &#38; jQuery 
    * CSS3 
    * HTML5 
    * SVG<p>Learn more: <a href=\"http://visual.ly/about/jobs\" rel=\"nofollow\">http://visual.ly/about/jobs</a>"
    post_urls = ["http://visual.ly/about/jobs"]

    assert_equal(@company_parser.parse(post_content, post_urls), "Visual.ly", "Company name is directly in the URL.TLD")
  end

  test "should recognize common dictionary work company names" do
    post_content = "Riot Games, Santa Monica, CA<p>Come work on the game League of Legends, one of the most popular PC games in the world.<p>We're looking for a lot of things, including Ruby/Rails, Erlang, Java, C++, Flex, and PHP developers.<p><a href=\"http://www.riotgames.com/careers/job-openings-0\" rel=\"nofollow\">http://www.riotgames.com/careers/job-openings-0</a><p>If you're a Ruby, Java, or Erlang developer you can email me directly.  My email is in my profile."
    post_urls = ["http://www.riotgames.com/careers/job-openings-0"]

    assert_equal(@company_parser.parse(post_content, post_urls), "Riot Games", "Company name is made up of common dictionary words in URL")
  end

  test "should not match company names in a URL that is not mentioned in the post" do
    post_content = "San Francisco, CA<p>VerticalResponse is hiring for a lot of great positions:<p>* Ruby on Rails Developers<p>* Ruby on Rails Architect<p>* Director of Product Management<p>* Search Engine Marketing (SEM) Analyst<p>* Senior QA Automation Engineer<p>* Online Marketing Specialist<p>* Product Manager<p>* Director of Acquisition Marketing<p>* Senior Financial Analyst<p>* Customer Relations Specialist<p>VR is an established and successful, privately held company in SF for the last 10 years. We work with Rails 3, Git, JQuery, Rspec, backbone.js, Haml, Sass, TDD, pair programming, agile development and other leading technologies (you don't need to have experience with all of these). I've been working there as an engineer for 7 months now and really enjoy it.<p>Occasional work from home is allowed if you have an important appointment or need to keep germs out of the office. We have happy hour on Fridays and the fridge is stocked with a wide variety of beer, so we'll sometimes end the day with a cold brew while we finish pairing on a difficult problem.<p>Apply here: <a href=\"http://jobvite.com/m?3RB34fwj\" rel=\"nofollow\">http://jobvite.com/m?3RB34fwj</a>"
    post_urls = ["http://jobvite.com/m?3RB34fwj"]
    
    assert_no_match(/[jJ]\s*[oO]\s*[bB]\s*[vV]\s*[iI]\s*[tT]\s*[eE]/, 
                    @company_parser.parse(post_content, post_urls), 
                    "Company name is not mentioned in the URL")
  end

  test "should match based on word occurences" do
    post_content = "New York City<p>Scholastic (the children's book publisher)<p>- Game Design &#38; Production Intern<p>- Game Art Intern<p>Both are six month paid internships. If you're in school, we're happy to work with you to set up academic credit. Full time preferred, but part time is possible as well.<p>gbrown@scholastic.com"
    post_urls = []

    assert_equal(@company_parser.parse(post_content, post_urls), "Scholastic", "Company name can be deduced by strange word occurences")
  end
end
