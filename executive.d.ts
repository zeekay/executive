interface executive {
  (command: string | any[], options?: any, callback?: any): Promise<any>
  interactive: executive
  parallel: executive
  quiet: executive
  serial: executive
  strict: executive
  sync: executive
}
declare var executive: executive
