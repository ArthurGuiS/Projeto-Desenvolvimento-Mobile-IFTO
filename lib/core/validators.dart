/// Utilitários de validação para a aplicação.
class Validators {
  /// Valida o formato padrão de um e-mail.
  static bool isEmailValido(String email) {
    if (email.isEmpty) return false;
    final RegExp regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  /// Valida o CPF através do cálculo de dígitos verificadores.
  static bool isCpfValido(String cpf) {
    // Remove qualquer caractere que não seja número
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    // Verifica tamanho ou se todos os números são iguais (ex: 00000000000)
    if (cpf.length != 11) return false;
    if (cpf.split('').every((char) => char == cpf[0])) return false;

    // Cálculo do primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int digit1 = 11 - (sum % 11);
    if (digit1 >= 10) digit1 = 0;

    // Cálculo do segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int digit2 = 11 - (sum % 11);
    if (digit2 >= 10) digit2 = 0;

    // Verifica se os dígitos calculados conferem com os do CPF
    return cpf[9] == digit1.toString() && cpf[10] == digit2.toString();
  }
}
