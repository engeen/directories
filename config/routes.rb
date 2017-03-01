Directories::Engine.routes.draw do
  resources :directories, path: "dir/:dir_type" do
    get :inplace_popup, on: :collection
  end

  root to: 'directories#index'
end
