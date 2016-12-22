class CoursesController < ApplicationController
  include Markdown
  helper_method :markdown
  before_action :set_course, only: [ :edit, :show, :update, :add_term, :delete_term, :destroy, :statistics ]

  def new
    @course = Course.new
  end

  def create
    @course = Course.create(course_params)
    if @course.valid?
      @course.terms.create()
      redirect_to @course
    else
      render "new"
    end
  end

  def show
    @terms = @course.terms.reverse

    if params[:term_number]
      @term = @course.terms.find_by number: params[:term_number]
    else
      @term = @course.terms.last
    end
    raise ActionController::RoutingError.new 'Not Found' if @term.nil?

    @teacher_id = @course.teacher_id

    if signed_in? && current_user.id == @teacher_id
      @teacher = true
      @students = @term.students.includes(jobs: :tasks)
    else
      @students = @term.students.where(approved: true).includes(jobs: :tasks)
    end

    if signed_in? && current_user.student?
      @student = @term.students.find_by user: current_user
    end

    @tasks = @student.tasks if @student

    @tasks_left = 0
    @students.each do |student|
      @tasks_left += student.tasks_left_count
    end

    @assignments = @term.assignments.order(:id).includes(:problems)
  end

  def statistics
    @terms = @course.terms
    @teacher_id = @course.teacher_id
    @statistics = true

    if signed_in?
      if current_user.id == @teacher_id
        @teacher = true
      elsif current_user.student?
        @student = Student.where(approved: true,  user_id: current_user, term: @terms).any?
      end
    end

    @notes_number = @course.notes_number_hash
    @notes_total = @notes_number.values.sum

    @accepted_tasks = @terms.map(&:accepted_tasks_count)
    @accepted_tasks_total = @accepted_tasks.sum

    @first_try_accepted_number = @course.first_try_accepted_number_hash
    @first_try_accepted_total = @first_try_accepted_number.values.sum

    @attempts_to_pass_number = @course.attempts_to_pass_number_hash
    @attempts_to_pass_total = @attempts_to_pass_number.values.sum

    # @max_of_attempts_to_pass_number = @course.max_of_attempts_to_pass_number_hash
    # @max_of_attempts_to_pass_total = @max_of_attempts_to_pass_number.values.max

    # @min_attempts_number_problem = @course.min_attempts_number_problem_hash
    # @min_attempts_number_problem_total = @min_attempts_number_problem.values.min

    # @max_attempts_number_problem = @course.max_attempts_number_problem_hash
    # @max_attempts_number_problem_total = @max_attempts_number_problem.values.max

  end

  def index
    @courses = Course.all_hash
  end

  def edit
  end

  def update
    @course.update(course_params)
    redirect_to @course
  end

  def add_term # todo rewrite with ajax
    @course.terms.create()

    redirect_to :back
  end

  def delete_term
    @course.terms.last.destroy
    redirect_to @course
  end

  def destroy
    @course.destroy
    redirect_to courses_path
  end

  private
  def course_params
    params.require(:course).permit(:group_name, :name, :active).merge(teacher_id: current_user.id)
  end

  def set_course
    @course = Course.find(params[:id])
  end
end
