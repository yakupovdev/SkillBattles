package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.*;import com.skillbattles.backend.repository.ReportRepository;import com.skillbattles.backend.mapper.ReportMapper;import com.skillbattles.backend.exception.*;import java.util.Objects;import lombok.RequiredArgsConstructor;import org.springframework.stereotype.Service;import org.springframework.transaction.annotation.Transactional;
@Service @RequiredArgsConstructor public class ReportServiceImpl implements ReportService {
 private final ReportRepository repository;private final ReportMapper mapper;
 @Override @Transactional public ReportDto report(ReportCommandDto c){
  if("OTHER".equals(c.getReason())&&(c.getComment()==null||c.getComment().isBlank()))throw new FieldValidationException("comment","Comment is required for OTHER.");
  boolean created=repository.insert(c.getUserId(),c.getBattleId(),c.getRoundId(),c.getReason(),c.getComment())==1;
  var row=repository.findByUserIdAndBattleIdAndRoundId(c.getUserId(),c.getBattleId(),c.getRoundId()).orElseThrow();
  if(!row.getReason().equals(c.getReason())||!Objects.equals(row.getComment(),c.getComment()))throw new ConflictException("REPORT_ALREADY_EXISTS","A different report already exists for this round.");
  var dto=mapper.toDto(row);dto.setCreated(created);return dto;
 }
}
