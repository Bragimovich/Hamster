
module DataSetCorrectionHelper
  def output_missing_columns(header_cells)
    Hamster.logger.info "Missing Cell"
    header_cells.each do |h_cell|
      next if az_assessment_columns.include?(h_cell)
      Hamster.logger.info h_cell
    end
  end

  def output_missing_columns_for_enrollment(header_cells)
    Hamster.logger.info "Missing Cell"
    header_cells.each do |h_cell|
      next if az_enrollment_columns.include?(h_cell)
      Hamster.logger.info h_cell
    end
  end

  def output_missing_columns_for_dropout(header_cells)
    Hamster.logger.info "Missing Cell"
    header_cells.each do |h_cell|
      next if az_dropout_columns.include?(h_cell)
      Hamster.logger.info h_cell
    end
  end

  def output_missing_columns_for_cohort(header_cells)
    Hamster.logger.info "Missing Cell"
    header_cells.each do |h_cell|
      next if az_cohort_columns.include?(h_cell)
      Hamster.logger.info h_cell
    end
  end

  def correct_md5_hash_for_az_assessment
    b_inserted = true
    while b_inserted
      b_inserted = false
      AzAssessment.where(md5_hash: nil).limit(5000).each do |az_assessment|
        md5_hash = get_md5_hash(az_assessment)
        az_assessment.update(md5_hash: md5_hash)
        b_inserted = true
        Hamster.logger.info md5_hash
      end
    end
  end

  def correct_md5_hash_for_az_dropout
    AzDropout.where(md5_hash: nil).each do |az_dropout|
      md5_hash = get_md5_hash_az_dropout(az_dropout)
      az_dropout.update(md5_hash: md5_hash)
      Hamster.logger.info md5_hash
    end
  end

  def correct_md5_hash_for_az_enrollment
    AzEnrollment.where(md5_hash: nil).each do |az_enrollment|
      md5_hash = get_md5_hash_az_enrollment(az_enrollment)
      az_enrollment.update(md5_hash: md5_hash)
      Hamster.logger.info md5_hash
    end
  end

  def correct_md5_hash_for_az_cohort
    AzCohort.where(md5_hash: nil).each do |az_cohort|
      md5_hash = get_md5_hash_az_cohort(az_cohort)
      az_cohort.update(md5_hash: md5_hash)
      Hamster.logger.info md5_hash
    end
  end
end