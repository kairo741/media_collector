# Sistema de Configurações - Media Collector

## Visão Geral

O Media Collector agora possui um sistema completo de persistência de configurações que salva automaticamente as preferências do usuário e as mantém entre sessões do aplicativo.

## Funcionalidades Implementadas

### 1. **Persistência de Diretórios**
- **Diretório Selecionado**: Salva automaticamente a pasta escolhida pelo usuário
- **Diretórios Recentes**: Mantém um histórico das últimas 5 pastas utilizadas
- **Auto-scan**: Opção para escanear automaticamente na inicialização

### 2. **Thumbnails**
- **Geração Automática**: Cria thumbnails para arquivos de vídeo usando FFmpeg
- **Geração Local**: Thumbnails são gerados sob demanda
- **Configuração de Qualidade**: Baixa, Média ou Alta qualidade
- **Sem Cache Persistente**: Thumbnails são recriados quando necessário

### 3. **Configurações Gerais**
- **Extensões Excluídas**: Lista de extensões ignoradas durante o escaneamento
- **Configurações de Thumbnails**: Habilitar/desabilitar e definir qualidade
- **Auto-scan**: Escanear automaticamente na inicialização

## Tecnologias Utilizadas

### **Hive** (Banco de Dados Local)
- Armazena configurações complexas
- Performance otimizada para leitura/escrita
- Suporte a tipos complexos (Map, List, etc.)

### **SharedPreferences** (Configurações Simples)
- Usado para migração de dados antigos
- Backup para configurações básicas

## Estrutura dos Arquivos

```
lib/
├── core/
│   ├── models/
│   │   ├── user_settings.dart          # Modelo de configurações
│   │   └── user_settings.g.dart        # Gerado pelo build_runner
│   └── services/
│       └── settings_service.dart       # Serviço de gerenciamento
├── ui/
│   ├── providers/
│   │   └── media_provider.dart         # Integração com configurações
│   └── widgets/
│       └── settings_dialog.dart        # Interface de configurações
```

## Como Usar

### 1. **Acessar Configurações**
- Clique no ícone de engrenagem (⚙️) na barra superior
- Configure thumbnails, auto-scan e extensões excluídas

### 2. **Diretórios Recentes**
- Após selecionar uma pasta, ela aparece na lista de "Pastas Recentes"
- Clique em qualquer pasta recente para acessá-la rapidamente

### 3. **Thumbnails**
- Habilitados por padrão com qualidade média
- Gerados automaticamente quando necessário
- Sem cache persistente, gerados sob demanda

### 4. **Auto-scan**
- Quando habilitado, escaneia automaticamente a pasta salva na inicialização
- Útil para manter a biblioteca sempre atualizada

## Configurações Disponíveis

### **Thumbnails**
- ✅ **Habilitar/Desabilitar**: Controla se thumbnails são gerados
- 🎨 **Qualidade**: 
  - Baixa: Rápido, menor qualidade
  - Média: Padrão, boa qualidade
  - Alta: Lento, melhor qualidade

### **Geral**
- 🔄 **Auto-scan**: Escanear automaticamente na inicialização
- 🚫 **Extensões Excluídas**: Lista de extensões ignoradas (ex: .tmp, .nfo)

## Dados Salvos

### **Hive Boxes**
- `user_settings`: Configurações principais

### **Configurações Persistidas**
```dart
{
  "selectedDirectory": "C:/Videos",
  "recentDirectories": ["C:/Videos", "D:/Movies"],
  "autoScanOnStartup": true,
  "enableThumbnails": true,
  "thumbnailQuality": "medium",
  "excludedExtensions": [".tmp", ".nfo"]
}
```

## Migração de Dados

O sistema suporta migração automática de configurações antigas:
1. Tenta carregar do Hive (novo sistema)
2. Se não encontrar, tenta carregar do SharedPreferences (sistema antigo)
3. Se não encontrar, cria configurações padrão

## Limpeza de Dados

### **Thumbnails**
- Os thumbnails são gerados localmente e não são salvos no cache
- Eles são recriados automaticamente quando necessário

### **Reset Completo**
- Use o botão "Limpar" na barra superior
- Remove todas as configurações e dados salvos

## Performance

### **Otimizações Implementadas**
- Geração local de thumbnails sem cache persistente
- Carregamento lazy de configurações
- Migração automática sem perda de dados

### **Recomendações**
- Para bibliotecas grandes, use qualidade "Baixa" ou "Média" para thumbnails
- Os thumbnails são gerados sob demanda, economizando espaço
- Use extensões excluídas para ignorar arquivos desnecessários

## Troubleshooting

### **Problemas Comuns**

1. **Thumbnails não aparecem**
   - Verifique se FFmpeg está instalado
   - Confirme se thumbnails estão habilitados nas configurações

2. **Configurações não salvam**
   - Verifique permissões de escrita no diretório do app
   - Tente resetar as configurações

3. **Performance lenta**
   - Reduza a qualidade dos thumbnails
   - Os thumbnails são gerados sob demanda
   - Adicione extensões desnecessárias à lista de exclusão

### **Logs de Debug**
O sistema registra logs importantes:
- Inicialização do SettingsService
- Salvamento de configurações
- Erros de carregamento/migração

## Próximas Melhorias

- [ ] Backup/restore de configurações
- [ ] Sincronização com nuvem
- [ ] Configurações por perfil de usuário
- [ ] Otimização da geração de thumbnails