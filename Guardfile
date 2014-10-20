guard :rubocop, all_on_start: false do
  watch(/.+\.(rb|rake)$/)
  watch(/(?:.+\/)?\.rubocop\.yml$/) { |m| File.dirname(m[0]) }
end
