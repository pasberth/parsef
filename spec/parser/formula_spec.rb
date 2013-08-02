# coding: utf-8

# Environmental variable `FORMULAV' is symbols separated with spaces for the using variables.
ENV["FORMULAV"] = "α β γ"

describe "formula" do

  context "when prefix operator" do
    example { expect(`formula "(incr α)" ++ α <<< "x"`).to eq "x\n" }
    example { expect(`formula "(incr α)" ++ α <<< "x\n++"`).to eq "x\n++\n" }
    example { expect(`formula "(incr α)" ++ α <<< "x\n++\ny"`).to eq "x\n(incr y)\n" }
  end

  context "when postfix operator" do
    example { expect(`formula "(incr α)" α ++ <<< "x"`).to eq "x\n" }
    example { expect(`formula "(incr α)" α ++ <<< "x\n++"`).to eq "(incr x)\n" }
    example { expect(`formula "(incr α)" α ++ <<< "x\n++\ny"`).to eq "(incr x)\ny\n" }
  end

  context "when infix operator" do

    example { expect(`formula "(append α β)" α ++ β <<< "x"`).to eq "x\n" }
    example { expect(`formula "(append α β)" α ++ β <<< "x\n++"`).to eq "x\n++\n" }
    example { expect(`formula "(append α β)" α ++ β <<< "x\n++\ny"`).to eq "(append x y)\n" }
  end
end