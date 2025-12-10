/// Service for AI-powered report generation
/// Converts inspector photo metadata into professional API 510 findings and recommendations

class ReportGenerationService {
  /// Generates structured findings and recommendations from photo metadata
  /// Returns a map with 'findings' and 'recommendations' lists
  static Map<String, List<Map<String, String>>> generateReport({
    required List<Map<String, dynamic>> photoData,
    required String equipmentTag,
    required String equipmentDescription,
  }) {
    List<Map<String, String>> findings = [];
    List<Map<String, String>> recommendations = [];
    
    for (int i = 0; i < photoData.length; i++) {
      final componentType = photoData[i]['componentType'] ?? 'Unknown Component';
      final conditionStatus = photoData[i]['conditionStatus'] ?? 'Unknown';
      final inspectorComment = photoData[i]['comment'] ?? '';
      final photoNumber = i + 1;
      final findingNumber = '1.${i + 1}';
      
      // Generate finding statement
      String findingStatement = _generateFindingStatement(
        findingNumber: findingNumber,
        componentType: componentType,
        conditionStatus: conditionStatus,
        inspectorComment: inspectorComment,
        photoNumber: photoNumber,
      );
      
      findings.add({
        'number': findingNumber,
        'statement': findingStatement,
        'photoNumber': photoNumber.toString(),
        'componentType': componentType,
        'conditionStatus': conditionStatus,
      });
      
      // Generate recommendation statement
      String recommendationStatement = _generateRecommendationStatement(
        findingNumber: findingNumber,
        conditionStatus: conditionStatus,
        componentType: componentType,
      );
      
      recommendations.add({
        'number': findingNumber,
        'statement': recommendationStatement,
        'conditionStatus': conditionStatus,
      });
    }
    
    return {
      'findings': findings,
      'recommendations': recommendations,
    };
  }
  
  /// Generates professional finding statement from metadata
  static String _generateFindingStatement({
    required String findingNumber,
    required String componentType,
    required String conditionStatus,
    required String inspectorComment,
    required int photoNumber,
  }) {
    // Map condition status to professional terminology
    String conditionDescription = _getConditionDescription(conditionStatus);
    
    // Build professional finding statement
    String finding = '$findingNumber. Visual inspection of the $componentType revealed $conditionDescription';
    
    // Add inspector observation details
    if (inspectorComment.isNotEmpty) {
      finding += '. Inspector notes: $inspectorComment';
    }
    
    // Add photo reference
    finding += ' (Refer to Photo $photoNumber)';
    
    return finding;
  }
  
  /// Generates professional recommendation statement based on condition
  static String _generateRecommendationStatement({
    required String findingNumber,
    required String conditionStatus,
    required String componentType,
  }) {
    // Handle "Nil" condition
    if (conditionStatus.toLowerCase() == 'nil') {
      return '$findingNumber. Nil.';
    }
    
    // Generate recommendations based on condition severity
    switch (conditionStatus.toLowerCase()) {
      case 'satisfactory':
        return '$findingNumber. Component found in satisfactory condition. Continue routine maintenance and monitoring during next scheduled inspection.';
      
      case 'minor corrosion':
        return '$findingNumber. Monitor the area for progression of corrosion. Re-inspect during next scheduled turnaround. Consider protective coating if deterioration continues.';
      
      case 'moderate corrosion':
        return '$findingNumber. Conduct ultrasonic thickness testing to determine remaining wall thickness. Repair or replace affected section if thickness is below minimum required. Implement corrosion protection measures.';
      
      case 'severe corrosion':
        return '$findingNumber. Immediate action required. Conduct comprehensive NDT (UT, RT, or PT) to assess extent of damage. Replace affected $componentType section. Investigate root cause and implement corrosion mitigation strategy.';
      
      case 'deformation':
        return '$findingNumber. Perform detailed dimensional analysis and structural assessment. Evaluate impact on pressure containment integrity. Repair or replace if deformation exceeds allowable tolerances per API 510 standards.';
      
      case 'crack detected':
        return '$findingNumber. Immediate attention required. Perform dye penetrant or magnetic particle testing to determine crack extent. Remove from service until crack is evaluated and repaired per ASME Section VIII requirements. Implement weld repair procedure.';
      
      case 'leakage':
        return '$findingNumber. Immediate isolation and repair required. Identify leak source through pressure testing. Replace gaskets, seals, or perform welded repair as necessary. Verify integrity through hydrostatic test before return to service.';
      
      case 'damaged':
        return '$findingNumber. Assess damage severity and impact on structural integrity. Conduct fitness-for-service evaluation per API 579. Repair or replace damaged $componentType. Ensure compliance with original design specifications.';
      
      case 'requires attention':
        return '$findingNumber. Further investigation required. Schedule detailed inspection with appropriate NDT methods. Monitor condition closely. Take corrective action based on detailed assessment findings.';
      
      default:
        return '$findingNumber. To be monitored during next scheduled inspection opportunity. Follow API 510 recommended inspection practices for $componentType.';
    }
  }
  
  /// Maps condition status to professional description
  static String _getConditionDescription(String conditionStatus) {
    switch (conditionStatus.toLowerCase()) {
      case 'satisfactory':
        return 'that the component is in satisfactory and serviceable condition with no visible defects or anomalies';
      
      case 'nil':
        return 'no observable defects or conditions requiring documentation';
      
      case 'minor corrosion':
        return 'minor surface corrosion with localized pitting. The affected area shows superficial oxidation with no significant material loss';
      
      case 'moderate corrosion':
        return 'moderate corrosion with visible material degradation. Surface shows scaling and pitting that may affect structural integrity';
      
      case 'severe corrosion':
        return 'severe corrosion with significant material loss and widespread deterioration. Immediate attention required to maintain pressure vessel integrity';
      
      case 'deformation':
        return 'visible deformation from the original manufactured profile. The component shows signs of mechanical stress or impact damage';
      
      case 'crack detected':
        return 'visible cracking in the material surface. Crack propagation poses risk to structural integrity and requires immediate assessment';
      
      case 'leakage':
        return 'evidence of active or previous leakage. Visible staining, seepage, or pressure drop indicates loss of containment';
      
      case 'damaged':
        return 'physical damage to the component structure. Damage may have resulted from mechanical impact, thermal stress, or operational conditions';
      
      case 'requires attention':
        return 'conditions that warrant further investigation and monitoring. Anomalies detected require additional assessment to determine severity';
      
      default:
        return 'conditions that have been documented for evaluation';
    }
  }
  
  /// Generates comprehensive summary findings section
  static String generateSummaryFindings(List<Map<String, String>> findings) {
    if (findings.isEmpty) {
      return 'No findings documented during this inspection.';
    }
    
    StringBuffer summary = StringBuffer();
    summary.writeln('The following findings were documented during the visual inspection:');
    summary.writeln();
    
    for (var finding in findings) {
      summary.writeln(finding['statement']);
      summary.writeln();
    }
    
    return summary.toString();
  }
  
  /// Generates comprehensive summary recommendations section
  static String generateSummaryRecommendations(List<Map<String, String>> recommendations) {
    if (recommendations.isEmpty) {
      return 'No recommendations at this time. Equipment found in satisfactory condition.';
    }
    
    StringBuffer summary = StringBuffer();
    summary.writeln('Based on the inspection findings, the following recommendations are provided:');
    summary.writeln();
    
    for (var recommendation in recommendations) {
      summary.writeln(recommendation['statement']);
      summary.writeln();
    }
    
    return summary.toString();
  }
}
