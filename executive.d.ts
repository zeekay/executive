declare function exec(command: string | any[], options?: any, callback?: any): Promise<any>

declare namespace exec {
  export function interactive(command: string | any[], options?: any, callback?: any): Promise<any>
  export function parallel(command: string | any[], options?: any, callback?: any): Promise<any>
  export function quiet(command: string | any[], options?: any, callback?: any): Promise<any>
  export function serial(command: string | any[], options?: any, callback?: any): Promise<any>
  export function strict(command: string | any[], options?: any, callback?: any): Promise<any>
  export function sync(command: string | any[], options?: any, callback?: any): any
}

export = exec
