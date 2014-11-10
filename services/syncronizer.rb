require 'config/configuration'

class Syncronizer
  FILE_NAME = 'tmp/.lock'

  LONG_TRANSACTION_MESSAGE = <<-msg
Обработка новых лотов занимает слишком много времени. \
Возможно нужно удалить файл `#{FILE_NAME}`.
  msg

  def self.perform(&block)
    new.perform(&block)
  end

  def perform
    if lock_file_exist?
      long_transaction? and fail LONG_TRANSACTION_MESSAGE
      return
    end
    lock
    yield
    unlock
  rescue Exception => e
    unlock
    raise e
  end

  private

  def lock_file_exist?
    File.exist?(FILE_NAME)
  end

  def long_transaction?
    file_age > timeout
  end

  def lock
    File.new(FILE_NAME, 'w')
  end

  def unlock
    File.delete(FILE_NAME)
  end

  def file_age
    (Time.now - File.ctime(FILE_NAME)) / 60
  end

  def timeout
    Configuration.integration.lot.timeout
  end
end
