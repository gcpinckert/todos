require "pg"

class DatabasePersistence
  def initialize
    @db = PG.connect(dbname: "todos")
  end

  def find_list(id)
    # @session[:lists].select { |list| list[:id] == id }.first
  end

  def all_lists
    sql = "SELECT * FROM lists;"
    result = @db.exec(sql)
    result.map do |tuple|
      { id: tuple["id"], name: tuple["name"], todos: []}
    end
    # Format: [ {id:, name:, todos:}, ...etc ]
  end

  def create_new_list(list_name)
    # list_id = next_list_id
    # @session[:lists] << { id: list_id, name: list_name, todos: [] }
  end

  def delete_list(list_id)
    # @session[:lists].delete_if { |list| list[:id] == list_id }
  end

  def update_list_name(id, new_name)
    # list = find_list(id)
    # list[:name] = new_name
  end

  def create_new_todo(list_id, todo_name)
    # list = find_list(list_id)
    # todo_id = next_todo_id(list[:todos])
    # list[:todos] << { id: todo_id, name: todo_name, completed: false }
  end

  def delete_todo_from_list(list_id, todo_id)
    # list = find_list(list_id)
    # binding.pry
    # list[:todos].delete_if { |todo| todo[:id] == todo_id }
  end

  def update_todo_status(list_id, todo_id, new_status)
    # list = find_list(list_id)
    # todo = list[:todos].select { |t| t[:id] == todo_id }.first
    # todo[:completed] = new_status
  end

  def mark_all_todos_completed(list_id)
    # list = find_list(list_id)
    # list[:todos].each do |todo|
    #   todo[:completed] = true
    # end
  end
end
