test "examples" do
  `cd example && rake -I../lib`
  assert $?.exitstatus == 0
end
