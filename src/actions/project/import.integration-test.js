import * as testing from '../../lib/testing'

const shell = require('shelljs')

const execOpts = {
  shell: shell.which('bash'),
  silent: true,
}

describe(`Command 'liq project import'`, () => {
  let testConfig
  let playground
  beforeEach(() => {
    testConfig = testing.setup()
    testConfig.metaInit()
    playground = `${testConfig.home}/playground`
  })
  afterEach(() => testConfig.cleanup())

  test.each([
        // TODO: provide a case that's not part of an org
        // ['ld-cli', 'ld-cli'],
        ['@liquid-labs/lc-entities-model', '@liquid-labs/lc-entities-model'],
        ['https://github.com/Liquid-Labs/lc-entities-model', '@liquid-labs/lc-entities-model'],
        [testing.localRepoUrl, '@liquid-labs/lc-entities-model']])
      ("with '%s' successfully clone project.", (importSpec, projectName) => {
    const result = shell.exec(`HOME=${testConfig.home} liq project import ${importSpec}`, execOpts)
    const expectedOutput = new RegExp(`^'${projectName}' imported into playground.[\s\n]*$`)

    expect(result.stderr).toEqual('')
    expect(result.stdout).toMatch(expectedOutput)
    expect(result.code).toEqual(0);
    ['README.md', '.git'].forEach((i) => expect(shell.test('-e', `${playground}/${projectName}/${i}`)).toBe(true))
  })
})