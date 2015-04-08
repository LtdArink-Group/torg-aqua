require 'aqua/projects_endpoint'
require 'models/app_variable'
require 'models/ksazd/invest_project_name'
require 'models/mapping/project_department'
require 'services/loggers'

class Projects
  PROCESSED_DATE_KEY = 'projects.processed_date'
  LAST_SYNC_TIME_KEY = 'projects.last_sync_time'

  class << self
    def sync
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

    def processed_date
      if date = AppVariable.find(PROCESSED_DATE_KEY).value
        Date.strptime(date, '%d.%m.%Y')
      else
        Configuration.integration.project.start_date
      end
    end

    def last_sync_time
      if time = AppVariable.find(LAST_SYNC_TIME_KEY).value
        time
      else
        Configuration.integration.project.start_date
      end
    end
  end

  attr_accessor :logger

  def initialize
    @logger = Loggers.projects_logger
  end

  def sync
    logger.info "Обращение к веб-сервису: запрос проектов с #{start_date} по #{yesterday}"
    response = ProjectsEndpoint.query(start_date, yesterday)
    response.status == 'S' ? process(response.data) : error(response.message)
    self.last_sync_time = Time.now
  end

  private

  def start_date
    @start_date ||= format_date(processed_date + 1)
  end

  def yesterday
    format_date(Date.today)
  end

  def process(projects)
    logger.info "  Получено проектов: #{projects.size}"
    logger.info projects
    projects = projects.select { |p| p[:spp_parent].nil? }
    merge(projects) unless projects.empty?
  end

  def merge(projects)
    projects.each do |project|
      InvestProjectName.merge(*params(project))
    end
    self.processed_date = yesterday
    logger.info "  Обработано проектов: #{projects.size}"
  end

  def params(project)
    [project[:spp], name(project), department(project[:vernr].to_i)]
  end

  def name(project)
    project[:long_text].nil? ? project[:name] : project[:long_text]
  end

  def department(aqua_id)
    ProjectDepartment.lookup(aqua_id) or
      fail "Не удалось найти заказчика КСАЗД для id #{aqua_id}"
  end

  def processed_date
    self.class.processed_date
  end

  def processed_date=(date)
    AppVariable.merge(PROCESSED_DATE_KEY, date)
  end

  def error(message)
    if message == 'За заданный период нет проектов'
      logger.info '  Нет изменений по проектам'
    else
      logger.error message
    end
  end

  def last_sync_time=(time)
    AppVariable.merge(LAST_SYNC_TIME_KEY, time)
  end

  def format_date(date)
    date.strftime('%d.%m.%Y')
  end
end
