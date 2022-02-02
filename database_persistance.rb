require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "todos")
    @logger = logger
  end

  # make private method?
  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1;"
    result = query(sql, id)
    tuple = result.first
    { id: tuple["id"].to_i, 
      name: tuple["name"], 
      todos: list_todos(tuple["id"]) }
  end

  def all_lists
    sql = "SELECT * FROM lists;"
    result = query(sql)

    result.map do |tuple|
      { id: tuple["id"].to_i, 
        name: tuple["name"], 
        todos: list_todos(tuple["id"]) }
    end
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1);"
    query(sql, list_name)
  end

  def delete_list(list_id)
    sql = "DELETE FROM lists WHERE id = $1;"
    query(sql, list_id)
  end

  def update_list_name(id, new_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2;"
    query(sql, new_name, id)
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

  private

  def list_todos(list_id)
    sql = "SELECT * FROM todos WHERE list_id = $1"
    result = query(sql, list_id)
    result.map do |tuple|
      { id: tuple["id"].to_i, 
        name: tuple["name"], 
        completed: convert_to_bool(tuple["completed"]) }
    end
  end

  def convert_to_bool(str)
    str == 't'
  end
end
