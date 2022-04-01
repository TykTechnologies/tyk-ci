ifelse(xREPO,<<portal>>,<<
before:
  hooks:
    - go mod tidy
    - ./copy-framework-files.sh
>>)dnl
