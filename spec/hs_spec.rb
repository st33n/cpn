require 'spec_helper'

describe CPN::Net do

  context "Hierarchical untimed net" do
    before do
      @cpn = CPN.build :Top do
        state :Waiting, "{ :make => 'Honda' }"
        state :OnRamp1
        state :OnRamp1Count, "0"
        state :Road1
        state :Road1Count, "0"
        state :AtDest

        page :OnRamp do
          state :In
          state :Out
          state :OutCount, "0"
          transition :Move do |t| 
            t.guard = "count < 5"
          end
          arc :In, :Move, "c"
          arc :Move, :Out, "c"
          arc :OutCount, :Move, "count"
          arc :Move, :OutCount, "count + 1"
        end

        page :Road do
          state :In
          state :Out
          state :InCount, "0"
          state :OutCount, "0"
          transition :Move do |t| 
            t.guard = "outcount < 5"
          end
          arc :In, :Move, "c"
          arc :InCount, :Move, "incount"
          arc :Move, :InCount, "incount - 1"
          arc :Move, :Out, "c"
          arc :OutCount, :Move, "outcount"
          arc :Move, :OutCount, "outcount + 1"
        end

        hs_transition :StartRamp, :OnRamp do |t|
          t.fuse :Waiting, :In
          t.fuse :OnRamp1, :Out
          t.fuse :OnRamp1Count, :OutCount
        end

        hs_transition :Move1, :Road do |t|
          t.fuse :OnRamp1, :In
          t.fuse :OnRamp1Count, :InCount
          t.fuse :Road1, :Out
          t.fuse :Road1Count, :OutCount
        end

        hs_transition :Move2, :Road do |t|
          t.fuse :Road1, :In
          t.fuse :Road1Count, :InCount
          t.fuse :AtDest, :Out
        end
      end
    end

    def statemap(page)
      ss = {}
      page.states.each do |n, s|
        ss["#{page.name}::#{n.to_s}"] = s.marking
      end
      page.transitions.each do |n, t|
        if t.respond_to? :states
          ss.merge!(statemap(t))
        end
      end
      ss
    end

    context "with initial markings" do
      describe "the stateset" do
        it "should be empty except for Top::Waiting and StartRamp::In" do
          statemap(@cpn).should == {
            'Top::Waiting'        => [ { :make => "Honda" } ],
            'Top::OnRamp1'        => [],
            'Top::OnRamp1Count'   => [ 0 ],
            'Top::Road1'          => [],
            'Top::Road1Count'     => [ 0 ],
            'Top::AtDest'         => [],
            'StartRamp::In'       => [ { :make => "Honda" } ],
            'StartRamp::Out'      => [],
            'StartRamp::OutCount' => [ 0 ],
            'Move1::In'           => [],
            'Move1::InCount'      => [ 0 ],
            'Move1::Out'          => [],
            'Move1::OutCount'     => [ 0 ],
            'Move2::In'           => [],
            'Move2::InCount'      => [ 0 ],
            'Move2::Out'          => [],
            'Move2::OutCount'     => [ 0 ]
          }
        end
      end
    end

    context "after occurring once, " do
      before do
        @cpn.occur_next.should_not be_nil
      end

      describe "the stateset" do
        it "should have a car on Top::OnRamp1, StartRamp::Out and Move1::In" do
          statemap(@cpn).should == {
            'Top::Waiting'        => [],
            'Top::OnRamp1'        => [ { :make => "Honda" } ],
            'Top::OnRamp1Count'   => [ 1 ],
            'Top::Road1'          => [],
            'Top::Road1Count'     => [ 0 ],
            'Top::AtDest'         => [],
            'StartRamp::In'       => [],
            'StartRamp::Out'      => [ { :make => "Honda" } ],
            'StartRamp::OutCount' => [ 1 ],
            'Move1::In'           => [ { :make => "Honda" } ],
            'Move1::InCount'      => [ 1 ],
            'Move1::Out'          => [],
            'Move1::OutCount'     => [ 0 ],
            'Move2::In'           => [],
            'Move2::InCount'      => [ 0 ],
            'Move2::Out'          => [],
            'Move2::OutCount'     => [ 0 ]
          }
        end
      end

      context "twice, " do
        before do
          @cpn.occur_next.should_not be_nil
        end

        describe "the stateset" do
          it "should have a car on Top::Road1, Move1::Out and Move2::In" do
            statemap(@cpn).should == {
              'Top::Waiting'        => [],
              'Top::OnRamp1'        => [],
              'Top::OnRamp1Count'   => [ 0 ],
              'Top::Road1'          => [ { :make => "Honda" } ],
              'Top::Road1Count'     => [ 1 ],
              'Top::AtDest'         => [],
              'StartRamp::In'       => [],
              'StartRamp::Out'      => [],
              'StartRamp::OutCount' => [ 0 ],
              'Move1::In'           => [],
              'Move1::InCount'      => [ 0 ],
              'Move1::Out'          => [ { :make => "Honda" } ],
              'Move1::OutCount'     => [ 1 ],
              'Move2::In'           => [ { :make => "Honda" } ],
              'Move2::InCount'      => [ 1 ],
              'Move2::Out'          => [],
              'Move2::OutCount'     => [ 0 ]
            }
          end
        end

        context "thrice, " do
          before do
            @cpn.occur_next.should_not be_nil
          end

          describe "the stateset" do
            it "should have a car on Top::AtDest and Move2::Out" do
              statemap(@cpn).should == {
                'Top::Waiting'        => [],
                'Top::OnRamp1'        => [],
                'Top::OnRamp1Count'   => [ 0 ],
                'Top::Road1'          => [],
                'Top::Road1Count'     => [ 0 ],
                'Top::AtDest'         => [ { :make => "Honda" } ],
                'StartRamp::In'       => [],
                'StartRamp::Out'      => [],
                'StartRamp::OutCount' => [ 0 ],
                'Move1::In'           => [],
                'Move1::InCount'      => [ 0 ],
                'Move1::Out'          => [],
                'Move1::OutCount'     => [ 0 ],
                'Move2::In'           => [],
                'Move2::InCount'      => [ 0 ],
                'Move2::Out'          => [ { :make => "Honda" } ],
                'Move2::OutCount'     => [ 1 ]
              }
            end
          end

          describe "the net" do
            it "should no longer be able to occur" do
              @cpn.occur_next.should be_nil
            end
          end
        end
      end
    end
  end

end
