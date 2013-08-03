describe "between" do

  example { expect(`between '[' ']' cat -E <<< "a\n[\nb\n]\nc"`).to eq <<-EOF }
a
b$
c
  EOF

  example { expect(`between "'" "'" cat -E <<< "a\n'\nb\n'\nc"`).to eq <<-EOF }
a
b$
c
  EOF

end