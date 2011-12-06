require 'spec_helper'

describe "HS timed CPN::Net" do
  CAR1 = { :id => 1 }
  CAR2 = { :id => 2 }
  CAR3 = { :id => 3 }

  context "Hierarchical timed net" do
    before(:all) do
      @cpn = CPN.build :Top do
        state :Waiting, "{ :id => 3 }.ready_at(6), { :id => 1 }.ready_at(1), { :id => 2 }.ready_at(2)"
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
            t.guard = "count < 1"
          end
          arc :In, :Move, "c"
          arc :Move, :Out, "c.ready_at(+3)"
          arc :OutCount, :Move, "count"
          arc :Move, :OutCount, "count + 1"
        end

        page :Road do
          state :In
          state :Out
          state :InCount, "0"
          state :OutCount, "0"
          transition :Move do |t| 
            t.guard = "outcount < 1"
          end
          arc :In, :Move, "c"
          arc :InCount, :Move, "incount"
          arc :Move, :InCount, "incount - 1"
          arc :Move, :Out, "c.ready_at(+3)"
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
            'Top::Waiting'        => [ CAR3, CAR1, CAR2 ],
            'Top::OnRamp1'        => [],
            'Top::OnRamp1Count'   => [ 0 ],
            'Top::Road1'          => [],
            'Top::Road1Count'     => [ 0 ],
            'Top::AtDest'         => [],
            'StartRamp::In'       => [ CAR3, CAR1, CAR2 ],
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

      describe "the time" do
        it "should be 0" do
          @cpn.time.should == 0
        end
      end
    end

    context "after advancing the time and occurring once," do
      before(:all) do
        @cpn.occur_next.should be_nil
        @cpn.advance_time
        @cpn.occur_next.should_not be_nil
      end

      describe "the time" do
        it "should be 1" do
          @cpn.time.should == 1
        end
      end

      describe "the stateset" do
        it "should have moved car 1 onto Top::OnRamp1, StartRamp::Out and Move1::In" do
          statemap(@cpn).should == {
            'Top::Waiting'        => [ CAR3, CAR2 ],
            'Top::OnRamp1'        => [ CAR1 ],
            'Top::OnRamp1Count'   => [ 1 ],
            'Top::Road1'          => [],
            'Top::Road1Count'     => [ 0 ],
            'Top::AtDest'         => [],
            'StartRamp::In'       => [ CAR3, CAR2 ],
            'StartRamp::Out'      => [ CAR1 ],
            'StartRamp::OutCount' => [ 1 ],
            'Move1::In'           => [ CAR1 ],
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
        before(:all) do
          @cpn.occur_next.should be_nil
          @cpn.advance_time
          @cpn.occur_next.should_not be_nil
        end

        describe "the stateset" do
          it "should have car 1 on Top::Road1, Move1::Out and Move2::In" do
            statemap(@cpn).should == {
              'Top::Waiting'        => [ CAR3, CAR2 ],
              'Top::OnRamp1'        => [],
              'Top::OnRamp1Count'   => [ 0 ],
              'Top::Road1'          => [ CAR1 ],
              'Top::Road1Count'     => [ 1 ],
              'Top::AtDest'         => [],
              'StartRamp::In'       => [ CAR3, CAR2 ],
              'StartRamp::Out'      => [],
              'StartRamp::OutCount' => [ 0 ],
              'Move1::In'           => [],
              'Move1::InCount'      => [ 0 ],
              'Move1::Out'          => [ CAR1 ],
              'Move1::OutCount'     => [ 1 ],
              'Move2::In'           => [ CAR1 ],
              'Move2::InCount'      => [ 1 ],
              'Move2::Out'          => [],
              'Move2::OutCount'     => [ 0 ]
            }
          end
        end

        describe "the time" do
          it "should be 4" do
            @cpn.time.should == 4
          end
        end

        context "thrice (same time), " do
          before(:all) do
            @cpn.occur_next.should_not be_nil
          end

          describe "the stateset" do
            it "should move car 2 onto the ramp" do
              statemap(@cpn).should == {
                'Top::Waiting'        => [ CAR3 ],
                'Top::OnRamp1'        => [ CAR2 ],
                'Top::OnRamp1Count'   => [ 1 ],
                'Top::Road1'          => [ CAR1 ],
                'Top::Road1Count'     => [ 1 ],
                'Top::AtDest'         => [],
                'StartRamp::In'       => [ CAR3 ],
                'StartRamp::Out'      => [ CAR2 ],
                'StartRamp::OutCount' => [ 1 ],
                'Move1::In'           => [ CAR2 ],
                'Move1::InCount'      => [ 1 ],
                'Move1::Out'          => [ CAR1 ],
                'Move1::OutCount'     => [ 1 ],
                'Move2::In'           => [ CAR1 ],
                'Move2::InCount'      => [ 1 ],
                'Move2::Out'          => [],
                'Move2::OutCount'     => [ 0 ]
              }
            end
          end

        end
      end
    end
  end

end
