require "sinatra"
require "sinatra/reloader"
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