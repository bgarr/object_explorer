require 'spec_helper'
require 'date'
require './lib/object_explorer.rb'
require 'active_support/core_ext/hash/deep_transform_values'
require 'active_support/core_ext/object/deep_dup'
require 'active_support/core_ext/object/blank' 

RSpec.describe 'ObjectExplorer' do
  let(:shallow_hash) do
    {
      a: [],
      b: nil,
      c: 0
    }
  end

  let(:hash_with_arrays) do
    {
      d: [
        1,
        { a: Date.today, b: [ {}, { a: 0, b: nil } ] },
        []
      ],
     e: "another"
    }
  end

  let(:deep_hash) do
    shallow_hash
      .merge(hash_with_arrays)
      .merge(
        {
          f: "yet another",
          g: {
            a: { a: [ "last" ], b: Date.today }
          }
        }
      )
  end

  describe '.new' do
    it 'raises ArgumentError unless passed a hash' do
      expect { ObjectExplorer.new({}) }.not_to raise_error
      expect { ObjectExplorer.new }.to raise_error(ArgumentError)
      expect { ObjectExplorer.new([]) }.to raise_error(ArgumentError)
      expect { ObjectExplorer.new(0) }.to raise_error(ArgumentError)
      expect { ObjectExplorer.new("a") }.to raise_error(ArgumentError)
    end
  end

  describe '#explore' do
    let(:empty_hash_explorer) { ObjectExplorer.new({}) }
    let(:shallow_hash_explorer) { ObjectExplorer.new(shallow_hash) }
    let(:hash_with_arrays_explorer) { ObjectExplorer.new(hash_with_arrays) }
    let(:deep_hash_explorer) { ObjectExplorer.new(deep_hash) }

    describe 'default selection' do
      it 'returns the original data' do
        expect(empty_hash_explorer.explore).to eq({})
        expect(shallow_hash_explorer.explore).to eq(shallow_hash)
        expect(hash_with_arrays_explorer.explore).to eq(hash_with_arrays)
        expect(deep_hash_explorer.explore).to eq(deep_hash)
      end
    end

    describe 'select none' do
      let(:none) { ->(*_args) { false } }

      it 'returns an empty hash' do
        expect(empty_hash_explorer.explore(select: none)).to eq({})
        expect(shallow_hash_explorer.explore(select: none)).to eq({})
        expect(hash_with_arrays_explorer.explore(select: none)).to eq({})
        expect(deep_hash_explorer.explore(select: none)).to eq({})
      end
    end

    describe 'custom selection' do
      it 'returns selected elements, maintaining nesting & preserving array position, if desired' do
        nils = ->(node, _path, _tree) { node.nil? }

        expect(deep_hash_explorer.explore(select: nils)).to eq(
          {
            b: nil,
            d: [ { b: [ { :b=>nil } ] } ]
          }
        )
        expect(deep_hash_explorer.explore(select: nils, preserve_array_indexes: true)).to eq(
          {
            b: nil,
            d: [ ObjectExplorer::NoValue, { b: [ ObjectExplorer::NoValue, { :b=>nil } ] } ]
          }
        )
      end
    end

    describe 'diffs' do
      let(:altered_deep_hash) do
        altered_deep_hash = deep_hash.deep_dup
        altered_deep_hash[:b] = deep_hash[:d].deep_dup
        altered_deep_hash.delete(:d)

        altered_deep_hash
      end

      it 'returns a diff from another object' do
        expect(deep_hash_explorer.diff(altered_deep_hash)).to eq(
          {
            b: nil,
            d: deep_hash[:d]
          }
        )
      end

      describe 'customized diff output' do
        let(:my_diff_report) do
          lambda do |node, path, _tree|
            {
              node: node,
              altered_node: path.present? ? altered_deep_hash.dig(*path) : ObjectExplorer::NoValue,
              some_other_value: "default"
            }
          end
        end

        it 'returns data formatted however you like' do
          expect(deep_hash_explorer.diff(altered_deep_hash, report: my_diff_report)).to eq(
            {
              b: {
                node: nil,
                altered_node: deep_hash[:d],
                some_other_value: "default"
              },
            d: {
              node: deep_hash[:d],
              altered_node: nil,
              some_other_value: "default"
            }
          })
        end
      end
    end

    context 'compare with Hash#deep_transform_values' do
      it 'can filter values, preserving minimal structure' do
        dates = ->(node, _path, _tree) { node.is_a?(Date) }
        only_date_values = deep_hash_explorer.explore(select: dates)
        expect(only_date_values).to eq({
          d: [{ a: Date.today }],
          g: { a: { b: Date.today } }
        })
        only_date_values_in_place = deep_hash_explorer.explore(select: dates, preserve_array_indexes: true)
        expect(only_date_values_in_place).to eq({
          d: [ ObjectExplorer::NoValue, { a: Date.today }],
          g: { a: { b: Date.today } }
        })

        deeply_transformed_compacted_values = deep_hash.deep_transform_values do |node|
          node if node.is_a? Date
        end.compact
        # Hash#deep_transform_values, even when compacted, contain spurious info.
        # { a: [],
        #   d: [ nil, { a: Sun, 21 Jun 2020, b: [ {}, { a: nil, b: nil } ] }, [] ],
        #   g: { a: { a: [nil], b: Sun, 21 Jun 2020 } }
        # }
        expect(deeply_transformed_compacted_values).not_to eq(only_date_values)
      end
    end
  end
end
