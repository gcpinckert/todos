require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"

require_relative "database_persistance"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, escape_html: true

end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistance.rb"
end

helpers do
  def all_todos_complete?(list)
    incomplete_todos_count(list) == 0 && total_todos(list) > 0
  end

  def list_class(list)
    "complete" if all_todos_complete?(list)
  end

  def incomplete_todos_count(list)
    list[:todos].reject { |todo| todo[:completed] }.size
  end

  def total_todos(list)
    list[:todos].size
  end

  def sorted_lists(lists, &block)
    complete, incomplete = lists.partition { |list| all_todos_complete?(list) }
    incomplete.each(&block)
    complete.each(&block)
  end

  def sorted_todos(todos, &block)
    complete, incomplete = todos.partition { |todo| todo[:completed] }
    incomplete.each(&block)
    complete.each(&block)
  end
end

before do
  @storage = DatabasePersistence.new(logger)
end

# Return an error message if the list name is invalid, else nil
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "The list name must be between 1-100 characters."
  elsif @storage.all_lists.any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

# Return the correct list if params are valid
def get_list(id)
  list = @storage.find_list(id)
  if list
    list
  else
    session[:error] = "The specified list was not found."
    redirect "/lists"
  end
end

# Return an error if todo is invalid, else nil
def error_for_todo(name)
  "Todo must be between 1 and 100 characters." unless (1..100).cover? name.size
end

get "/" do
  redirect "/lists"
end

# View list of all lists
get "/lists" do
  @lists = @storage.all_lists
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    @storage.create_new_list(list_name)
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# Display a single Todo List
get "/lists/:id" do
  id = params[:id].to_i
  @list = get_list(id)
  erb :list_todos, layout: :layout
end

# Render the Edit List form
get "/lists/:id/edit" do
  list_id = params[:id].to_i
  @list = get_list(list_id)
  erb :edit_list, layout: :layout
end

# Edit existing list name
post "/lists/:id" do
  id = params[:id].to_i
  @list = get_list(id)
  new_list_name = params[:list_name].strip
  error = error_for_list_name(new_list_name)

  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @storage.update_list_name(list_num, new_list_name)
    session[:success] = "The list name has been changed."
    redirect "/lists/#{@list[:id]}"
  end
end

# Delete existing list
post "/lists/:id/delete" do
  id = params[:id].to_i

  @storage.delete_list(id)
  
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "This list has been deleted."
    redirect "/lists"
  end
end

# Add new todo to a list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = get_list(@list_id)
  text = params[:todo].strip
  
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list_todos, layout: :layout
  else
    @storage.create_new_todo(@list_id, text)
    session[:success] = "The todo was added."
    redirect "/lists/#{@list_id}"
  end
end

# Delete todo from list
post "/lists/:list_id/todos/:todo_id/delete" do
  @list_id = params[:list_id].to_i
  @list = get_list(@list_id)
  todo_id = params[:todo_id].to_i

  @storage.delete_todo_from_list(@list_id, todo_id)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been deleted."
    redirect "/lists/#{@list_id}"
  end
end

# Toggle completed state of todo
post "/lists/:list_id/todos/:todo_id" do
  @list_id = params[:list_id].to_i
  @list = get_list(@list_id)

  todo_id = params[:todo_id].to_i
  completed = (params[:completed] == "true")

  @storage.update_todo_status(@list_id, todo_id, completed)

  session[:success] = "The todo has been updated"
  redirect "/lists/#{@list_id}"
end

# Completes all todos in a list
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = get_list(@list_id)
  
  @storage.mark_all_todos_completed(@list_id)

  session[:success] = "All todos have been completed."
  redirect "/lists/#{@list_id}"
end
