def flatten_hash(value, path = nil)
  {}.merge(*value.map { |k, v| flatten(v, [path, k].compact.join('_').to_sym) })
end

def flatten_array(value, path)
  { path.to_sym => value.map { |v| flatten(v, path) } }
end

def flatten_other(value, path)
  { path.to_sym => value }
end

def flatten(value, path = nil)
  return flatten_hash(value, path) if value.is_a?(Hash)
  return flatten_array(value, path) if value.is_a?(Array)

  flatten_other(value, path)
end
