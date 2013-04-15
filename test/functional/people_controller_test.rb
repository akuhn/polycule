require 'test_helper'

class PeopleControllerTest < ActionController::TestCase
  setup do
    @person = people(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:people)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create person" do
    assert_difference('Person.count') do
      post :create, person: { birthday: @person.birthday, city: @person.city, country: @person.country, email: @person.email, facebook: @person.facebook, fetlife: @person.fetlife, gender: @person.gender, house: @person.house, name: @person.name, nickname: @person.nickname, note: @person.note, okcupid: @person.okcupid, state: @person.state, twitter: @person.twitter }
    end

    assert_redirected_to person_path(assigns(:person))
  end

  test "should show person" do
    get :show, id: @person
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @person
    assert_response :success
  end

  test "should update person" do
    put :update, id: @person, person: { birthday: @person.birthday, city: @person.city, country: @person.country, email: @person.email, facebook: @person.facebook, fetlife: @person.fetlife, gender: @person.gender, house: @person.house, name: @person.name, nickname: @person.nickname, note: @person.note, okcupid: @person.okcupid, state: @person.state, twitter: @person.twitter }
    assert_redirected_to person_path(assigns(:person))
  end

  test "should destroy person" do
    assert_difference('Person.count', -1) do
      delete :destroy, id: @person
    end

    assert_redirected_to people_path
  end
end
