# Media Collector

Um gerenciador pessoal de filmes e séries desenvolvido em Flutter, focado no controle local de arquivos de mídia com interface moderna e intuitiva.

## 📋 Descrição

O Media Collector é uma aplicação desktop que permite organizar, buscar e reproduzir sua coleção pessoal de filmes e séries. Com uma interface responsiva e funcionalidades avançadas de filtragem, o aplicativo oferece uma experiência completa para gerenciar arquivos de mídia locais.

## ✨ Funcionalidades

### 🎬 Gerenciamento de Mídia
- **Escaneamento Inteligente**: Detecta automaticamente filmes e séries em pastas selecionadas
- **Reconhecimento de Padrões**: Identifica temporadas e episódios baseado em padrões de nomenclatura
- **Suporte a Múltiplos Formatos**: MP4, AVI, MKV, MOV, WMV, FLV, WEBM, M4V, 3GP
- **Extração de Metadados**: Ano, qualidade, idioma, tamanho do arquivo

### 🔍 Busca e Filtros
- **Busca em Tempo Real**: Pesquisa por título, nome do arquivo, série, ano ou qualidade
- **Filtros por Tipo**: Separação entre filmes e séries
- **Ordenação Inteligente**: Organização automática por nome e episódios

### 📺 Visualização de Séries
- **Agrupamento por Temporada**: Organização automática de episódios
- **Thumbnails Automáticas**: Geração de miniaturas usando FFmpeg
- **Navegação Intuitiva**: Interface expansível para cada temporada

### 🎮 Reprodução e Acesso
- **Reprodução Direta**: Abre arquivos no player padrão do sistema
- **Acesso Rápido**: Abre pastas contendo os arquivos
- **Informações Detalhadas**: Exibe metadados completos dos arquivos

### 🎨 Interface Moderna
- **Design Responsivo**: Adapta-se a diferentes tamanhos de tela
- **Tema Escuro**: Interface otimizada para uso noturno
- **Grid Adaptativo**: Layout que se ajusta automaticamente
- **Estatísticas em Tempo Real**: Contadores de filmes, séries e tamanho total

## 🚀 Instalação

### Pré-requisitos
- Flutter SDK 3.8.1 ou superior
- Dart SDK
- FFmpeg (opcional, para geração de thumbnails)

### Passos de Instalação

1. **Clone o repositório**
   ```bash
   git clone https://github.com/kairo741/media_collector.git
   cd media_collector
   ```

2. **Instale as dependências**
   ```bash
   flutter pub get
   ```

3. **Configure o FFmpeg (opcional)**
   - Baixe o FFmpeg para Windows
   - Extraia para `C:\ffmpeg\`
   - Atualize o caminho em `lib/core/utils/ffmpeg_thumb_helper.dart`:
     ```dart
     static const String ffmpegPath = r'C:\ffmpeg\bin\ffmpeg.exe';
     ```

4. **Execute o aplicativo**
   ```bash
   flutter run -d windows
   ```

## 📖 Como Usar

### Primeiro Acesso
1. **Selecione uma Pasta**: Clique em "Selecionar Pasta" e escolha o diretório com seus arquivos de mídia
2. **Aguarde o Escaneamento**: O aplicativo irá analisar todos os arquivos automaticamente
3. **Explore sua Coleção**: Use os filtros e busca para encontrar o que procura

### Navegação
- **Filmes**: Clique em um filme para reproduzir diretamente
- **Séries**: Clique em uma série para ver todos os episódios organizados por temporada
- **Informações**: Use o ícone de informações para ver detalhes completos do arquivo
- **Pasta**: Use o ícone de pasta para abrir o diretório contendo o arquivo

### Busca e Filtros
- **Barra de Busca**: Digite para filtrar por título, série, ano ou qualidade
- **Filtros**: Use os chips "Todos", "Filmes" ou "Séries" para filtrar por tipo
- **Estatísticas**: Veja contadores em tempo real na barra superior

## 🏗️ Estrutura do Projeto

```
lib/
├── core/
│   ├── models/
│   │   └── media_item.dart          # Modelo de dados para itens de mídia
│   ├── services/
│   │   ├── media_player_service.dart # Serviço de reprodução
│   │   └── media_scanner_service.dart # Serviço de escaneamento
│   └── utils/
│       ├── ffmpeg_thumb_helper.dart  # Geração de thumbnails
│       └── string_extensions.dart    # Extensões de string
├── ui/
│   ├── pages/
│   │   └── home_screen.dart         # Tela principal
│   ├── providers/
│   │   └── media_provider.dart      # Gerenciamento de estado
│   ├── theme/
│   │   └── theme.dart               # Configurações de tema
│   └── widgets/
│       ├── directory_selector.dart  # Seletor de pasta
│       ├── media_item_card.dart     # Card de item de mídia
│       ├── media_list_view.dart     # Lista de mídia
│       └── series_episodes_screen.dart # Tela de episódios
└── main.dart                        # Ponto de entrada
```

## 🔧 Tecnologias Utilizadas

- **Flutter**: Framework de desenvolvimento
- **Provider**: Gerenciamento de estado
- **File Picker**: Seleção de diretórios
- **URL Launcher**: Abertura de arquivos e pastas
- **Path**: Manipulação de caminhos
- **Video Thumbnail**: Geração de miniaturas
- **FFmpeg**: Processamento de vídeo (opcional)

## 📱 Compatibilidade

- **Windows**: Suporte completo
- **Linux**: Suporte básico (sem FFmpeg)
- **macOS**: Suporte básico (sem FFmpeg)

## 🎯 Padrões de Nomenclatura Suportados

### Séries
- `Série.S01E02.Qualidade.Idioma.mkv`
- `Série 1x02.Qualidade.Idioma.mkv`
- `S01E01 - Título do Episódio.mkv`
- `01 Título do Episódio 02 Outro Episódio.mkv`
- Novos padrões serão adicionados futuramente

### Filmes
- `Filme (2023).Qualidade.Idioma.mkv`
- `Filme.2023.Qualidade.Idioma.mkv`
- - Novos padrões serão adicionados futuramente

## 🐛 Solução de Problemas

### FFmpeg não encontrado
- Verifique se o FFmpeg está instalado e o caminho está correto
- O aplicativo funcionará sem FFmpeg, mas sem thumbnails

### Arquivos não detectados
- Verifique se os arquivos têm extensões suportadas
- Certifique-se de que o padrão de nomenclatura está correto

### Erro de permissão
- Execute o aplicativo como administrador
- Verifique as permissões da pasta selecionada

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 👨‍💻 Autor

Desenvolvido com ❤️ para organizar coleções de mídia de forma eficiente e elegante.

---

**Media Collector** - Organize sua coleção de filmes e séries de forma inteligente!  