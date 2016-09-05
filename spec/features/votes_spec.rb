require 'rails_helper'

feature 'Votes' do

  background do
    @manuela = create(:user, verified_at: Time.now)
    @pablo = create(:user)
  end

  feature 'Debates' do
    background { login_as(@manuela) }

    scenario "Index shows user votes on debates" do

      debate1 = create(:debate)
      debate2 = create(:debate)
      debate3 = create(:debate)
      create(:vote, voter: @manuela, votable: debate1, vote_flag: true)
      create(:vote, voter: @manuela, votable: debate3, vote_flag: false)

      visit debates_path

      within("#debates") do
        within("#debate_#{debate1.id}_votes") do
          within(".in-favor") do
            expect(page).to have_css("a.voted")
            expect(page).to_not have_css("a.no-voted")
          end

          within(".against") do
            expect(page).to have_css("a.no-voted")
            expect(page).to_not have_css("a.voted")
          end
        end

        within("#debate_#{debate2.id}_votes") do
          within(".in-favor") do
            expect(page).to_not have_css("a.voted")
            expect(page).to_not have_css("a.no-voted")
          end

          within(".against") do
            expect(page).to_not have_css("a.no-voted")
            expect(page).to_not have_css("a.voted")
          end
        end

        within("#debate_#{debate3.id}_votes") do
          within(".in-favor") do
            expect(page).to have_css("a.no-voted")
            expect(page).to_not have_css("a.voted")
          end

          within(".against") do
            expect(page).to have_css("a.voted")
            expect(page).to_not have_css("a.no-voted")
          end
        end
      end
    end

    feature 'Single debate' do

      scenario 'Show no votes' do
        visit debate_path(create(:debate))

        expect(page).to have_content "No votes"

        within('.in-favor') do
          expect(page).to have_content "0%"
          expect(page).to_not have_css("a.voted")
          expect(page).to_not have_css("a.no-voted")
        end

        within('.against') do
          expect(page).to have_content "0%"
          expect(page).to_not have_css("a.voted")
          expect(page).to_not have_css("a.no-voted")
        end
      end

      scenario 'Update', :js do
        visit debate_path(create(:debate))

        find('.in-favor a').click
        find('.against a').click

        within('.in-favor') do
          expect(page).to have_content "0%"
          expect(page).to have_css("a.no-voted")
        end

        within('.against') do
          expect(page).to have_content "100%"
          expect(page).to have_css("a.voted")
        end

        expect(page).to have_content "1 vote"
      end

      scenario 'Trying to vote multiple times', :js do
        visit debate_path(create(:debate))

        find('.in-favor a').click
        expect(page).to have_content "1 vote"
        find('.in-favor a').click
        expect(page).to_not have_content "2 votes"

        within('.in-favor') do
          expect(page).to have_content "100%"
        end

        within('.against') do
          expect(page).to have_content "0%"
        end
      end

      scenario 'Show' do
        debate = create(:debate)
        create(:vote, voter: @manuela, votable: debate, vote_flag: true)
        create(:vote, voter: @pablo, votable: debate, vote_flag: false)

        visit debate_path(debate)

        expect(page).to have_content "2 votes"

        within('.in-favor') do
          expect(page).to have_content "50%"
          expect(page).to have_css("a.voted")
        end

        within('.against') do
          expect(page).to have_content "50%"
          expect(page).to have_css("a.no-voted")
        end
      end

      scenario 'Create from debate show', :js do
        visit debate_path(create(:debate))

        find('.in-favor a').click

        within('.in-favor') do
          expect(page).to have_content "100%"
          expect(page).to have_css("a.voted")
        end

        within('.against') do
          expect(page).to have_content "0%"
          expect(page).to have_css("a.no-voted")
        end

        expect(page).to have_content "1 vote"
      end

      scenario 'Create in index', :js do
        create(:debate)
        visit debates_path

        within("#debates") do

          find('.in-favor a').click

          within('.in-favor') do
            expect(page).to have_content "100%"
            expect(page).to have_css("a.voted")
          end

          within('.against') do
            expect(page).to have_content "0%"
            expect(page).to have_css("a.no-voted")
          end

          expect(page).to have_content "1 vote"
        end
        expect(current_path).to eq(debates_path)
      end
    end
  end

  feature 'Proposals' do
    background { login_as(@manuela) }

    scenario "Index shows user votes on proposals" do
      proposal1 = create(:proposal)
      proposal2 = create(:proposal)
      proposal3 = create(:proposal)
      create(:vote, voter: @manuela, votable: proposal1, vote_flag: true)

      visit proposals_path

      within("#proposals") do
        within("#proposal_#{proposal1.id}_votes") do
          expect(page).to have_content "You have already supported this proposal. Share it!"
        end

        within("#proposal_#{proposal2.id}_votes") do
          expect(page).to_not have_content "You have already supported this proposal. Share it!"
        end

        within("#proposal_#{proposal3.id}_votes") do
          expect(page).to_not have_content "You have already supported this proposal. Share it!"
        end
      end
    end

    feature 'Single proposal' do
      background do
        @proposal = create(:proposal)
      end

      scenario 'Show no votes' do
        visit proposal_path(@proposal)
        expect(page).to have_content "No supports"
      end

      scenario 'Trying to vote multiple times', :js do
        visit proposal_path(@proposal)

        within('.supports') do
          find('.in-favor a').click
          expect(page).to have_content "1 support"

          expect(page).to_not have_selector ".in-favor a"
        end
      end

      scenario 'Show' do
        create(:vote, voter: @manuela, votable: @proposal, vote_flag: true)
        create(:vote, voter: @pablo, votable: @proposal, vote_flag: true)

        visit proposal_path(@proposal)

        within('.supports') do
          expect(page).to have_content "2 supports"
        end
      end

      scenario 'Create from proposal show', :js do
        visit proposal_path(@proposal)

        within('.supports') do
          find('.in-favor a').click

          expect(page).to have_content "1 support"
          expect(page).to have_content "You have already supported this proposal. Share it!"
        end
      end

      scenario 'Create in listed proposal in index', :js do
        create_featured_proposals
        visit proposals_path

        within("#proposal_#{@proposal.id}") do
          find('.in-favor a').click

          expect(page).to have_content "1 support"
          expect(page).to have_content "You have already supported this proposal. Share it!"
        end
        expect(current_path).to eq(proposals_path)
      end

      scenario 'Create in featured proposal in index', :js do
        visit proposals_path

        within("#proposal_#{@proposal.id}") do
          find('.in-favor a').click

          expect(page).to have_content "You have already supported this proposal. Share it!"
        end
        expect(current_path).to eq(proposals_path)
      end
    end
  end

  scenario 'Not logged user trying to vote debates', :js do
    debate = create(:debate)

    visit debates_path
    within("#debate_#{debate.id}") do
      find("div.votes").hover
      expect_message_you_need_to_sign_in
    end
  end

  scenario 'Not logged user trying to vote proposals', :js do
    proposal = create(:proposal)

    visit proposals_path
    within("#proposal_#{proposal.id}") do
      find("div.supports").hover
      expect_message_you_need_to_sign_in
    end

    visit proposal_path(proposal)
    within("#proposal_#{proposal.id}") do
      find("div.supports").hover
      expect_message_you_need_to_sign_in
    end
  end

  scenario 'Not logged user trying to vote comments in debates', :js do
    debate = create(:debate)
    comment = create(:comment, commentable: debate)

    visit comment_path(debate)
    within("#comment_#{comment.id}") do
      find("div.votes").hover
      expect_message_you_need_to_sign_in_to_vote_comments
    end
  end

  scenario 'Not logged user trying to vote comments in proposals', :js do
    proposal = create(:proposal)
    comment = create(:comment, commentable: proposal)

    visit comment_path(comment)
    within("#comment_#{comment.id}_reply") do
      find("div.votes").hover
      expect_message_you_need_to_sign_in_to_vote_comments
    end
  end

  scenario 'Anonymous user trying to vote debates', :js do
    user = create(:user)
    debate = create(:debate)

    Setting["max_ratio_anon_votes_on_debates"] = 50
    debate.update(cached_anonymous_votes_total: 520, cached_votes_total: 1000)

    login_as(user)

    visit debates_path
    within("#debate_#{debate.id}") do
      find("div.votes").hover
      expect_message_to_many_anonymous_votes
    end

    visit debate_path(debate)
    within("#debate_#{debate.id}") do
      find("div.votes").hover
      expect_message_to_many_anonymous_votes
    end
  end

  scenario "Anonymous user trying to vote proposals", :js do
    user = create(:user)
    proposal = create(:proposal)

    login_as(user)
    visit proposals_path

    within("#proposal_#{proposal.id}") do
      find("div.supports").hover
      expect_message_only_verified_can_vote_proposals
    end

    visit proposal_path(proposal)
    within("#proposal_#{proposal.id}") do
      find("div.supports").hover
      expect_message_only_verified_can_vote_proposals
    end
  end

  feature 'Spending Proposals' do
    background { login_as(@manuela) }

    feature 'Index' do
      scenario "Index shows user votes on proposals" do
        spending_proposal1 = create(:spending_proposal)
        spending_proposal2 = create(:spending_proposal)
        spending_proposal3 = create(:spending_proposal)
        create(:vote, voter: @manuela, votable: spending_proposal1, vote_flag: true)

        visit spending_proposals_path

        within("#investment-projects") do
          within("#spending_proposal_#{spending_proposal1.id}_votes") do
            expect(page).to have_content "You have already supported this. Share it!"
          end

          within("#spending_proposal_#{spending_proposal2.id}_votes") do
            expect(page).to_not have_content "You have already supported this. Share it!"
          end

          within("#spending_proposal_#{spending_proposal3.id}_votes") do
            expect(page).to_not have_content "You have already supported this. Share it!"
          end
        end
      end

      scenario 'Create from spending proposal index', :js do
        spending_proposal = create(:spending_proposal)
        visit spending_proposals_path

        within('.supports') do
          find('.in-favor a').click

          expect(page).to have_content "1 support"
          expect(page).to have_content "You have already supported this. Share it!"
        end
      end
    end

    feature 'Single spending proposal' do
      background do
        @proposal = create(:spending_proposal)
      end

      scenario 'Show no votes' do
        visit spending_proposal_path(@proposal)
        expect(page).to have_content "No supports"
      end

      scenario 'Trying to vote multiple times', :js do
        visit spending_proposal_path(@proposal)

        within('.supports') do
          find('.in-favor a').click
          expect(page).to have_content "1 support"

          expect(page).to_not have_selector ".in-favor a"
        end
      end

      scenario 'Create from proposal show', :js do
        visit spending_proposal_path(@proposal)

        within('.supports') do
          find('.in-favor a').click

          expect(page).to have_content "1 support"
          expect(page).to have_content "You have already supported this. Share it!"
        end
      end
    end

    scenario 'Disable voting on spending proposals', :js do
      login_as(@manuela)
      Setting["feature.spending_proposal_features.voting_allowed"] = nil
      spending_proposal = create(:spending_proposal)

      visit spending_proposals_path

      within("#spending_proposal_#{spending_proposal.id}") do
        find("div.supports").hover
        expect_message_voting_not_allowed
      end

      visit spending_proposal_path(spending_proposal)

      within("#spending_proposal_#{spending_proposal.id}") do
        find("div.supports").hover
        expect_message_voting_not_allowed
      end
    end
  end

  feature 'Investments' do

    let(:budget)  { create(:budget, phase: "selecting") }
    let(:group)   { create(:budget_group, budget: budget) }
    let(:heading) { create(:budget_heading, group: group) }

    background { login_as(@manuela) }

    feature 'Index' do

      scenario "Index shows user votes on proposals" do
        investment1 = create(:budget_investment, heading: heading)
        investment2 = create(:budget_investment, heading: heading)
        investment3 = create(:budget_investment, heading: heading)
        create(:vote, voter: @manuela, votable: investment1, vote_flag: true)

        visit budget_investments_path(budget_id: budget.id)

        within("#budget-investments") do
          within("#budget_investment_#{investment1.id}_votes") do
            expect(page).to have_content "You have already supported this. Share it!"
          end

          within("#budget_investment_#{investment2.id}_votes") do
            expect(page).to_not have_content "You have already supported this. Share it!"
          end

          within("#budget_investment_#{investment3.id}_votes") do
            expect(page).to_not have_content "You have already supported this. Share it!"
          end
        end
      end

      scenario 'Create from spending proposal index', :js do
        investment = create(:budget_investment, heading: heading, budget: budget)

        visit budget_investments_path(budget_id: budget.id)

        within('.supports') do
          find('.in-favor a').click

          expect(page).to have_content "1 support"
          expect(page).to have_content "You have already supported this. Share it!"
        end
      end
    end

    feature 'Single spending proposal' do
      background do
        @investment = create(:budget_investment, budget: budget)
      end

      scenario 'Show no votes' do
        visit budget_investment_path(budget, @investment)
        expect(page).to have_content "No supports"
      end

      scenario 'Trying to vote multiple times', :js do
        visit budget_investment_path(budget, @investment)

        within('.supports') do
          find('.in-favor a').click
          expect(page).to have_content "1 support"

          expect(page).to_not have_selector ".in-favor a"
        end
      end

      scenario 'Create from proposal show', :js do
        visit budget_investment_path(budget, @investment)

        within('.supports') do
          find('.in-favor a').click

          expect(page).to have_content "1 support"
          expect(page).to have_content "You have already supported this. Share it!"
        end
      end
    end

    scenario 'Disable voting on spending proposals', :js do
      login_as(@manuela)
      budget.update(phase: "on_hold")
      investment = create(:budget_investment, budget: budget)

      visit budget_investments_path(budget)

      within("#budget_investment_#{investment.id}") do
        find("div.supports").hover
        expect_message_selecting_not_allowed
      end

      visit budget_investment_path(budget, investment)

      within("#budget_investment_#{investment.id}") do
        find("div.supports").hover
        expect_message_selecting_not_allowed
      end
    end
  end

end
