/// Mapeo Nivel_Obesidad (salida del modelo) → recomendación dietética.
String dietaRecomendadaPara(String nivelObesidad) {
  switch (nivelObesidad) {
    case 'Peso_insuficiente':
      return 'Dieta hipercalórica';
    case 'Peso_normal':
      return 'Dieta equilibrada';
    case 'Sobrepeso_Nivel_I':
      return 'Dieta hipocalórica leve';
    case 'Sobrepeso_Nivel_II':
      return 'Dieta de bajo índice glucémico';
    case 'Obesidad_Tipo_I':
      return 'Dieta hipocalórica estricta (baja en carbohidratos)';
    case 'Obesidad_Tipo_II':
      return 'Dieta alta en proteínas y baja en carbohidratos';
    case 'Obesidad_Tipo_III':
      return 'Dieta muy baja en calorías';
    default:
      return 'Clasificación no reconocida; revise el modelo o los datos.';
  }
}
