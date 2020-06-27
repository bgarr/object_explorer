# ObjectExplorer

ObjectExplorer is a simple gem that separates the concern of traversing nested hash/array data structures (like those you would find among ActiveRecord associations). Unlike Rails 6.x's #deep_transform_values, it can handle any mix of nested hashes and arrays. Standard usage is below. There is also a utility method to generate diffs between objects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'object_explorer'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install object_explorer

## Usage

Typical usage is to initialize a new ObjectExplorer, passing in an object of interest. Then call explore to examine it and return some report on found nodes. The default selection mechanism returns all nodes, and the default report returns the node itself, so without parameters, the #explore method will just return the original object.

### Example
```ruby
my_explorer = ObjectExplorer.new(object_with_nested_hashes_and_arrays)
my_selection_proc = ->(node, _path, _tree) { <some criteria that resolve to a boolean> }
my_reporting_proc = ->(node, _path, _tree) { <any output appropriate to your needs> }
report = my_explorer.explore(select: my_selection_proc, report: my_reporting_proc)
```

The output is in a structure which mimics the initial object, but with only nodes represented those values selected in the original object.

In the case of arrays, unselected objects will not be reported, so the reported array in the output will only have elements representing selected nodes. If you wish to preserve the indices of elements in arrays, pass `preserve_array_indexes: true` to #explore.

There is also a #diff utility, which receives an object for comparison, but otherwise has the same signature as #explore
```ruby
diff_report = my_explorer.diff(some_other_object, <optional_reporting_proc>)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bgarr/object_explorer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/bgarr/object_explorer/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ObjectExplorer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bgarr/object_explorer/blob/master/CODE_OF_CONDUCT.md).
