class FriendsController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @friends = @user.friends
    @requests = @user.requested_friends
    @pending = @user.pending_friends
  end

  def create
    @user = current_user
    friend = User.find_by(id: params[:id])
    @user.friend_request(friend)

    redirect_to friends_path
  end

  def add
    @user = current_user
    friend = User.find_by(id: params[:id])
    @user.accept_request(friend)

    redirect_to friends_path
  end

  def reject
    @user = current_user
    friend = User.find_by(id: params[:id])
    @user.decline_request(friend)

    redirect_to friends_path
  end

  def remove
    @user = current_user
    friend = User.find_by(id: params[:id])
    @user.remove_friend(friend)

    redirect_to friends_path
  end

  def search
    @user = current_user
    @pending = @user.pending_friends

    @search = params[:search].downcase
    @results = User.all.select do |user|
      user_fullname = user.firstname.downcase + " " + user.lastname.downcase
      user_fullname == @search || user.email.downcase == @search
    end
  end
end
