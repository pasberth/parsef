describe "foldr" do

  example do
    expect(`foldl cat -E <<< "a"`).to eq "a\$\n"
  end

  example do
    expect(`foldl cat -E <<< "a\nb"`).to eq "a\$\nb\$\n"
  end

  example do
    expect(`foldl cat -E <<< "a\nb\nc"`).to eq "a\$\nb\$\nc\$\n"
  end

  example do
    expect(`foldl -@b cat -E <<< "a"`).to eq <<-EOF
a$
    EOF
  end

  example do
    expect(`foldl -@b cat -E <<< "a\nb"`).to eq <<-EOF
a$$
b$
    EOF
  end

  example do
    expect(`foldl -@b cat -E <<< "a\nb\nc"`).to eq <<-EOF
a$$
b$
c$
    EOF
  end

  example do
    expect(`foldl -@b cat -E <<< "a\nb\nc\nb\nd"`).to eq <<-EOF
a$$$
b$$
c$$
b$
d$
    EOF
  end

  example do
    expect(`foldl -@b -@d cat -E <<< "a\nb\nc\nd\ne"`).to eq <<-EOF
a$$$
b$$
c$$
d$
e$
    EOF
  end
end