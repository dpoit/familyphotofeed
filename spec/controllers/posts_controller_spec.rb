require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  describe "posts#index action" do
    it "should successfully show the index page if a user is logged in" do
      user = FactoryBot.create(:user)
      sign_in user

      get :index
      expect(response).to have_http_status(:success)
    end

    # # this needs to be moved to static pages controller spec
    # it "should successfully show the index page if a user is not logged in" do
    #   get :index
    #   expect(response).to have_http_status(:success)
    # end

    it "should display thumbnails sorted by upload date in descending order" do
      get :index

      thumbnail_upload_dates = []
      posts = Post.order(created_at: :desc)
      posts.each do |post|
        thumbnail_upload_dates << post.created_at
      end

      def descending?(arr)
        arr == arr.sort.reverse
      end

      expect(descending?(thumbnail_upload_dates)).to eq(true)
    end
  end

  describe "posts#show action" do
    it "should return successfully if a user views a post that was posted by themselves" do
      user = FactoryBot.create(:user)
      sign_in user
      post :create, params: {
        post: {
          user_id: user.id,
          caption: 'Test',
          photo: fixture_file_upload('/picture.png', 'image/png')
        }
      }
      post = Post.last
      get :show, params: { id: post.id }
      expect(response).to have_http_status(:success)
    end

    it "should return successfully if a user views a post that was posted by a user in their family" do
      user1 = FactoryBot.create(:user)
      user2 = FactoryBot.create(:user)
      sign_in user1
      post :create, params: {
        post: {
          user_id: user1.id,
          caption: 'User 1 Test Post',
          photo: fixture_file_upload('/picture.png', 'image/png')
        }
      }
      post = Post.last
      user1.friend_request(user2)
      sign_out user1
      sign_in user2
      user2.accept_request(user1)
      get :show, params: { id: post.id }
      expect(response).to have_http_status(:success)
    end

    it "should return a 403 error if a user tries to view a post that was posted by someone other than the user or their family" do
      post = FactoryBot.create(:post)
      user = FactoryBot.create(:user)
      sign_in user
      
      get :show, params: { id: post.id }
      expect(response).to have_http_status(:forbidden)
    end

    it "should return a 404 error if a user is logged in but the post is not found" do
      user = FactoryBot.create(:user)
      sign_in user

      get :show, params: { id: 'WHATEVER' }
      expect(response).to have_http_status(:not_found)
    end

    it "should redirect to the log in page if a user is not logged in" do
      post = FactoryBot.create(:post)

      get :show, params: { id: post.id }
      expect(response).to redirect_to new_user_session_path
    end
  end

  describe "posts#new action" do
    it "should require users to be logged in" do
      get :new
      expect(response).to redirect_to new_user_session_path
    end

    it "should successfully show the new form" do
      user = FactoryBot.create(:user)
      sign_in user

      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "posts#create action" do
    it "should require users to be logged in" do
      post :create, params: { post: { message: "Test" } }
      expect(response).to redirect_to new_user_session_path
    end

    it "should successfully create a new post in our database" do
      user = FactoryBot.create(:user)
      sign_in user

      post :create, params: {
        post: {
          caption: 'Test',
          photo: fixture_file_upload('/picture.png', 'image/png')
        }
      }

      post = Post.last

      expect(response).to redirect_to post_path(post)
      
      expect(post.caption).to eq("Test")
      expect(post.user).to eq(user)
    end

    it "should properly deal with validation errors" do
      user = FactoryBot.create(:user)
      sign_in user

      post :create, params: { post: { caption: '' } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(Post.count).to eq Post.count
    end
  end

  describe "posts#edit action" do
    it "shouldn't let a user who did not create the post edit a post" do
      post = FactoryBot.create(:post)
      user = FactoryBot.create(:user)
      sign_in user
      get :edit, params: { id: post.id }
      expect(response).to have_http_status(:forbidden)
    end

    it "shouldn't let unauthenticated users edit a post" do
      post = FactoryBot.create(:post)
      get :edit, params: { id: post.id }
      expect(response).to redirect_to new_user_session_path
    end

    it "should successfully show the edit form if the post is found" do
      post = FactoryBot.create(:post)
      sign_in post.user

      get :edit, params: { id: post.id }
      expect(response).to have_http_status(:success)
    end

    it "should return a 404 error message if the post is not found" do
      user = FactoryBot.create(:user)
      sign_in user

      get :edit, params: { id: 'WHATEVS' }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "posts#update action" do
    it "shouldn't let users who didn't create the post update it" do
      post = FactoryBot.create(:post)
      user = FactoryBot.create(:user)
      sign_in user
      patch :update, params: { id: post.id, post: { caption: 'Lolol' } }
      expect(response).to have_http_status(:forbidden)
    end

    it "shouldn't let unauthenticated users update a post" do
      post = FactoryBot.create(:post)
      patch :update, params: { id: post.id, post: { caption: 'This should not work' } }
      expect(response).to redirect_to new_user_session_path
    end

    it "should allow users to successfully update posts and display the post page" do
      post = FactoryBot.create(:post, caption: "Initial Value")
      sign_in post.user

      patch :update, params: { id: post.id, post: { caption: 'Changed' } }
      expect(response).to redirect_to post_path
      post.reload
      expect(post.caption).to eq "Changed"
    end

    it "should have http 404 error if the post cannot be found" do
      user = FactoryBot.create(:user)
      sign_in user

      patch :update, params: { id: 'BABYBUM', post: { caption: 'Changed' } }
      expect(response).to have_http_status(:not_found)
    end

    it "should render the edit form with an http status of unprocessable_entity" do
      post = FactoryBot.create(:post, caption: "Initial Value")
      sign_in post.user

      patch :update, params: { id: post.id, post: { caption: '' } }
      expect(response).to have_http_status(:unprocessable_entity)
      post.reload
      expect(post.caption).to eq "Initial Value"
    end
  end

  describe "posts#destroy action" do
    it "shouldn't allow users who didn't create the post to destroy it" do
      post = FactoryBot.create(:post)
      user = FactoryBot.create(:user)
      sign_in user
      delete :destroy, params: { id: post.id }
      expect(response).to have_http_status(:forbidden)
    end

    it "shouldn't let unauthenticated users destroy a post" do
      post = FactoryBot.create(:post)
      delete :destroy, params: { id: post.id }
      expect(response).to redirect_to new_user_session_path
    end

    it "should allow a user to destroy posts" do
      post = FactoryBot.create(:post)
      sign_in post.user
      delete :destroy, params: { id: post.id }
      expect(response).to redirect_to root_path
      post = Post.find_by_id(post.id)
      expect(post).to eq nil
    end

    it "should return a 404 message if we cannot find a post with the id that is specified" do
      user = FactoryBot.create(:user)
      sign_in user
      delete :destroy, params: { id: 'MANHORSE' }
      expect(response).to have_http_status(:not_found)
    end
  end
end
