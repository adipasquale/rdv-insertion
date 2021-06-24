class DepartmentsController < ApplicationController
  skip_before_action :authenticate_agent!, only: [:index]
  before_action :set_department, only: [:show]

  def index
    @departments = Department.all
  end

  def show
    authorize @department
  end

  private

  def set_department
    @department = Department.find(params[:id])
  end
end