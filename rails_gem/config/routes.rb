Rails.application.routes.draw do
  namespace :infrarecord do
    post "/"              => "infrarecord#statement"
    get  "/models"        => "infrarecord#models"
  end
end
