require 'state_machine'
class Story
  attr_accessor :prose, :experiment

  state_machine :phase, initial: :planning do
    state :ready
    state :introduction
    state :hook
    state :inspection
    state :conclusion

    event :finish_planning do
      transition :planning => :ready
    end
    before_transition any => :ready do |story, transition|
      story.prose = []
    end

    event :write_introduction do
      transition :ready => :hook
    end
    before_transition :ready => :hook do |story, transition|
      story.prose << 'Hello, this is an introduction.'
    end

    event :propose_experiment do
      transition :hook => :inspection
    end
    before_transition any => :inspection do |story, transition|
      story.experiment = Experiment.new
      story.prose << 'I proposed an experiment'
    end

    event :question_proposal do
      transition :inspection => :inspection
    end
    before_transition :inspection => :inspection do |story, transition|
      puts "questioning proposal"
      story.prose << 'Questioning proposal'

      if rand(2) == 0
        story.experiment.certainty *= 2
      else
        story.experiment.certainty -= 25
      end
    end

    event :accept_proposal do
      transition :inspection => :conclusion, if: :certain_experiment?
    end
    before_transition :inspection => :conclusion do |story, transition|
      puts "proposal was accepted"
      story.prose << 'proposal accepted'
    end

    event :reject_proposal do
      transition :inspection => :proposal, if: :certain_experiment?
    end
    before_transition :inspection => :proposal do |story, transition|
      puts "proposal was rejected"
      story.prose << 'proposal rejected'
    end

    event :write_conclusion do
      transition :conclusion => :conclusion
    end
    before_transition :conclusion => :conclusion do |story, transition|
      puts "conclusion"
      story.prose << 'conclusion'
    end
  end

  def title
    "#{qw(Bob Jim Joe).sample}'s Experiment"
  end

  def formatted_prose
    (self.prose || []).join ' '
  end

  def certain_experiment?
    self.experiment.certainty < 15 || self.experiment.certainty > 80
  end
end

class Experiment
  attr_accessor :materials, :certainty
  attr_accessor :measurement, :subject, :action, :stimuli

  def initialize
    self.certainty = 50
  end

  def description
    "measure #{measurement} #{subject}s #{action} [when #{stimuli}]"
    # measurement = how fast, how quickly, how X
  end

  def material_costs
    (materials || []).length * 50.0
  end

  def budget=(b)
    @budget = b
  end

  def budget
    @budget || material_costs
  end
end

def assert(msg, a)
  puts "asserting #{msg}"
  return if a

  puts "ASSERT FAILED: #{msg}: #{a}"
  exit 1
end

e = Experiment.new
assert "true is true", true
e.budget = 10
assert "budget overrides", e.budget == 10
e.budget = nil
assert "budget resets", e.budget != nil && e.budget != 10

story = Story.new
assert "story in planning mode", story.planning?
story.finish_planning
assert "story ready to write", story.ready?

story.write_introduction
assert "story has prose", story.prose && story.prose.length > 0
assert "story ready to hook", story.can_propose_experiment? && story.hook?

puts "\tIntroduction is:\n\n", story.formatted_prose

prior_prose = story.formatted_prose
story.propose_experiment
assert "story has experiment", story.experiment
assert "more prose was written", story.formatted_prose.length > prior_prose.length

until story.can_accept_proposal? || story.can_reject_proposal?
  prior_prose = story.formatted_prose

  story.question_proposal
  assert "questioning proposal adds prose", story.formatted_prose.length > prior_prose.length
end

story.accept_proposal if story.can_accept_proposal?
story.reject_proposal if story.can_reject_proposal?
story.write_conclusion