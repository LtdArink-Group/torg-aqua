require 'aqua/projects_endpoint'
require 'models/app_variable'
require 'models/ksazd/invest_project_name'
require 'models/mapping/project_department'
require 'services/loggers'

class Projects
  def self.sync
    new.tap do |s|
      begin
        s.sync
      rescue Exception => e
        s.logger.fatal "#{e.class}. #{e.message}\n#{e.backtrace.join("\n")}"
        Airbrake.notify(e)
        raise e
      end
    end
  end

  def initialize
    @logger = Loggers.projects_logger
  end

  def sync
    logger.info "Обращение к веб-сервису: запрос проектов с #{start_date} по #{yesterday}"
    response = ProjectsEndpoint.query(start_date, yesterday)
    if response.status == 'S'
      projects = select_top_level(response.data)
      merge(projects) unless projects.empty?
    else
      error(response.message)
    end
  end

  attr_accessor :logger

  private

  VARIABLE_KEY = 'processed_date.project'
  NO_MATCH_DEPART = 'Не удалось найти заказчика КСАЗД для id: '

  def select_top_level(projects)
    projects.select { |p| p[:spp_parent].nil? }
  end

  def merge(projects)
    count = 0
    projects.each do |project|
      InvestProjectName.merge(*params(project))
      count += 1
    end
    self.processed_date = yesterday
    logger.info "Обработано проектов: #{count}"
  end

  def params(project)
    [project[:spp], name(project), department(project[:vernr].to_i)]
  end

  def name(project)
    project[:long_text].nil? ? project[:name] : project[:long_text]
  end

  def department(aqua_id)
    ProjectDepartment.lookup(aqua_id) or fail NO_MATCH_DEPART + aqua_id.to_s
  end

  def start_date
    @start_date ||= format_date(processed_date + 1)
  end

  def processed_date
    if date = AppVariable.lookup(VARIABLE_KEY)
      Date.strptime(date, '%d.%m.%Y')
    else
      Configuration.integration.project.start_date
    end
  end

  def processed_date=(date)
    AppVariable.merge(VARIABLE_KEY, date)
  end

  def yesterday
    format_date(Date.today - 1)
  end

  def error(message)
    if message == 'За заданный период нет проектов'
      logger.info 'Нет изменений по проектам'
    else
      logger.error message
    end
  end

  def format_date(date)
    date.strftime('%d.%m.%Y')
  end
end
