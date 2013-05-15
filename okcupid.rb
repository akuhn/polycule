require 'net/http'
require 'nokogiri'

# Expects username and password in OKC_USER and OKC_PASSWD

class OKCupid
  def self.fetch url
    @@instance ||= OKCupid.new
    @@instance.fetch url 
  end
  def initialize
    @web = Net::HTTP.new('m.okcupid.com')
    p params = "username=#{username}&password=#{password}"
    r = @web.post('/login',params)
    puts r.body
    @cookie = r.to_hash['set-cookie'].collect{|m|m[/^.*?;/]}.join
    puts "OCKupid.initialize # => #{@cookie}"
  end
  def username
    ENV['OKC_USER']
  end
  def password
    ENV['OKC_PASSWD']
  end
  def fetch url
    u = URI.parse(url)
    name = u.path.split('/').last.downcase
    r = @web.get("/profile/#{name}", 'cookie' => @cookie)
    doc = Nokogiri::HTML(r.body)
    return unless doc.at('.screenname')
    age,gender = doc.at('.aso').content.split('/').map(&:strip)
    {
      name: doc.at('.screenname').content,
      age: age,
      gender: gender,
      picture: doc.at('.user img')['src'],
      link: "http://www.okcupid.com/profile/#{name}" 
    }
  end
end
