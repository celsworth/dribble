# frozen_string_literal: true

# Store the previous data sent to our frontend websocket so we can apply a diff
# to it on the next iteration and see what, if anything, has changed.
#
# This lets us cut down on sending huge lists of unchanged data to the frontend
# every few seconds.
#
# For this to work, the first member of each sub-array must be a key, usually
# a torrent hash.
#
#   dd = DataDiffer.new
#
#   # data = [[id1, 1], [id2, 2]]
#   diff = dd.diff((data)
#   # => returns entire thing, first diff => [[id1, 1], [id2, 2]]
#
#   data = [[id1, 2], [id2, 2]]
#   diff = dd.diff((data)
#   # => returns only differing sub-arrays => [[id1, 2]]
#
class DataDiffer
  def diff(data)
    ret = if @prev
            diff_arrays(@prev, data)
          else
            data
          end

    @prev = data

    ret
  end

  private

  # Given last and current are in format:
  # [[hash1, name1], [hash2, name2]] and [[hash1, name1], [hash2, newname2]]
  #
  # Compare them keyed by hash, and return the members that have changed in current
  # => [[hash2, newname2]]
  #
  def diff_arrays(last, current)
    # bit of an assumption that hash is the first array value here..
    l_hash = last.map { |l| [l[0], l] }.to_h
    c_hash = current.map { |c| [c[0], c] }.to_h

    c_hash.reject { |hash, c| c == l_hash[hash] }.values
  end
end
