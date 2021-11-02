require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

=begin
# session[:lists] data structure:
[
  { name: "list one", todos: [ {name: "a", completed: false}, { name: "b", completed: true } ] }
  { name: "list two", todos: [ {name: "a", completed: false}, { name: "b", completed: true } ] }
  # ... etc
]
=end

configure do
  enable :sessions
  set :session_secret, 'secret'
end

configure do
  set :erb, :escape_html => true
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
    incomplete.each { |list| yield list, lists.index(list) }
    complete.each { |list| yield list, lists.index(list) }
  end

  def sorted_todos(todos, &block)
    complete, incomplete = todos.partition { |todo| todo[:completed] }
    incomplete.each { |todo| yield todo, todos.index(todo) }
    complete.each { |todo| yield todo, todos.index(todo) }
  end
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View list of all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Return an error message if the list name is invalid, else nil
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "The list name must be between 1-100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# Display a single Todo List
get "/lists/:number" do
  @list_num = params[:number].to_i
  @list = session[:lists][@list_num]
  erb :list_todos, layout: :layout
end

# Render the Edit List form
get "/lists/:number/edit" do
  @list_num = params[:number].to_i
  @list = session[:lists][@list_num]
  erb :edit_list, layout: :layout
end

# Edit existing list name
post "/lists/:number" do
  @list_num = params[:number].to_i
  @list = session[:lists][@list_num]
  new_list_name = params[:list_name].strip
  error = error_for_list_name(new_list_name)

  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = new_list_name
    session[:success] = "The list name has been changed."
    redirect "/lists/#{@list_num}"
  end
end

# Delete existing list
post "/lists/:number/delete" do
  @list_num = params[:number].to_i
  session[:lists].delete_at(@list_num)
  session[:success] = "This list has been deleted."
  redirect "/lists"
end

# Return an error if todo is invalid, else nil
def error_for_todo(name)
  "Todo must be between 1 and 100 characters." unless (1..100).cover? name.size
end

# Add new todo to a list
post "/lists/:list_num/todos" do
  @list_num = params[:list_num].to_i
  @list = session[:lists][@list_num]
  text = params[:todo].strip
  
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list_todos, layout: :layout
  else
    @list[:todos] << { name: text, completed: false }
    @todos = @list[:todos]
    session[:success] = "The todo was added."
    redirect "/lists/#{@list_num}"
  end
end

# Delete todo from list
post "/lists/:list_num/todos/:todo_num/delete" do
  @list_num = params[:list_num].to_i
  todo_num = params[:todo_num].to_i
  @list = session[:lists][@list_num]

  @list[:todos].delete_at(todo_num)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{@list_num}"
end

# Toggle completed state of todo
post "/lists/:list_num/todos/:todo_num" do
  @list_num = params[:list_num].to_i
  todo_num = params[:todo_num].to_i
  @list = session[:lists][@list_num]
  completed = (params[:completed] == "true")

  @list[:todos][todo_num][:completed] = completed
  session[:success] = "The todo has been updated"
  redirect "/lists/#{@list_num}"
end

# Completes all todos in a list
post "/lists/:number/complete_all" do
  @list_num = params[:number].to_i
  @list = session[:lists][@list_num]
  
  @list[:todos].each do |todo|
    todo[:completed] = true
  end

  session[:success] = "All todos have been completed."
  redirect "/lists/#{@list_num}"
end
