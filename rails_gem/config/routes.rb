Rails.application.routes.draw do
  namespace :infrarecord do
    post "/"              => "infrarecord#statement"
  end
end
