ifelse(xREPO,<<portal>>,<<
before:
  hooks:
    - go mod tidy
    - ./ci/copy-framework-files.sh
>>)dnl
