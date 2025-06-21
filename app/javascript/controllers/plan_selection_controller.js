import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="plan-selection"
export default class extends Controller {
  static targets = [ "teamNameField", "teamNameInput" ]
  
  connect() {
    console.log("Plan selection controller connected")
    this.checkSelectedPlan()
  }
  
  checkSelectedPlan() {
    const selectedPlan = this.element.querySelector('input[name="user[plan_id]"]:checked')
    console.log("Selected plan:", selectedPlan)
    
    if (selectedPlan) {
      const planSegment = selectedPlan.getAttribute('data-plan-segment')
      console.log("Plan segment:", planSegment)
      
      if (planSegment === 'team') {
        this.showTeamField()
      } else {
        this.hideTeamField()
      }
    } else {
      this.hideTeamField()
    }
  }
  
  showTeamField() {
    if (this.hasTeamNameFieldTarget) {
      this.teamNameFieldTarget.classList.remove('hidden')
      if (this.hasTeamNameInputTarget) {
        this.teamNameInputTarget.setAttribute('required', 'required')
      }
    }
  }
  
  hideTeamField() {
    if (this.hasTeamNameFieldTarget) {
      this.teamNameFieldTarget.classList.add('hidden')
      if (this.hasTeamNameInputTarget) {
        this.teamNameInputTarget.removeAttribute('required')
      }
    }
  }
}