class CoursesController < ApplicationController
  def new
    @course = Course.new
  end

  def create
    @course = Course.create(course_params)
    @course.create_term
    redirect_to @course
  end

  def show
    @course = Course.find(params[:id])

    if params[:term_number]
      @term = @course.terms.where(number: params[:term_number]).first
    else
      @term = @course.terms.last
    end

    raise ActionController::RoutingError.new('Not Found') if @term.nil?

    @subscription = @term.students.where(user_id: current_user.id).first  
  end

  def add_term
    @course = Course.find(params[:id])
    @course.create_term

    redirect_to :back
  end

  private
  def course_params
    params.require(:course).permit(:group_name, :name).merge(teacher_id: current_user.id)
  end
end
