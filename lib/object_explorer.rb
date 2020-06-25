class ObjectExplorer
  attr_reader :tree

  class NoValue; end

  ALL_NODES = ->(_node, _path, _tree) { true }
  NODE_ITSELF = ->(node, _path, _tree) { node }

  def initialize(tree)
    raise ArgumentError unless tree.is_a? Hash

    @tree = tree
  end

  def explore(select: ALL_NODES, report: NODE_ITSELF, preserve_array_indexes: false)
    @output = {}
    @select = select
    @report = report
    @preserve_array_indexes = preserve_array_indexes
    traverse(tree)
    @output
  end

  def diff(otherObject, **args)
    explore(select: generate_diff_select(otherObject), **args)
  end

  private

  def traverse(node, path=[], parent=nil)
    case node
    when Hash
      traverse_hash(node, path, parent)
    when Array
      traverse_array(node, path, parent)
    end

    act_on_node(node, path, parent) if select?(node, path, parent)
  end

  def traverse_hash(node, path, _parent)
    node.each do |key, value|
      traverse(value, path + [key], node)
    end
  end

  def traverse_array(node, path, _parent)
    node.each_with_index do |value, i|
      traverse(value, path + [i], node)
    end
  end

  def act_on_node(node, path, _parent)
    node_report = @report.call(node, path, tree)
    assign_to_output(path, node_report)
  end

  def select?(node, path, parent)
    @select.call(node, path, parent)
  rescue StandardError
    false
  end

  def generate_diff_select(otherObject)
    lambda do |node, path, tree|
      return if node == tree

      node != otherObject.dig(*path)
    end
  end

  def assign_to_output(path, report)
    path.each_with_index.inject([tree, @output]) do |(tree_node, output_node), (key, index)|
      if index == path.length - 1
        output_node[key] = report
      else
        step_into_output(tree_node, output_node, key)
      end
    end
  end

  def step_into_output(tree_node, output_node, key)
    new_tree_node = tree_node[key]
    case output_node
    when Hash
      output_node[key] = tree_node[key].class.new
    when Array
      if @preserve_array_indexes && key > 0
        output_node[0..key] = Array.new(key){ NoValue }
        output_node[key] = tree_node[key].class.new
      else
        output_node[0..key] = tree_node[key].class.new
        key = 0
      end
    end

    [new_tree_node, output_node[key]]
  end
end
