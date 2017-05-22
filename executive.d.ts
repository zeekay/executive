export interface executive {
  (command: string | any[], options?: any, callback?: any): Promise<any>
  interactive: executive
  parallel: executive
  quiet: executive
  serial: executive
  strict: executive
  sync: (command: string | any[], options?: any, callback?: any) => any
}

declare global {
  var exec: executive
}

export default executive
