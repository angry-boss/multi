appraise "rails-5-2" do
  gem "rails", "~> 5.2.0"
end


appraise "rails-6-0" do
  gem "rails", "~> 6.0.0.rc1"
  platforms :ruby do
    gem 'sqlite3', '~> 1.4'
  end
end


appraise "rails-master" do
  gem "rails", git: 'https://github.com/rails/rails.git'
  platforms :ruby do
    gem 'sqlite3', '~> 1.4'
  end
end
