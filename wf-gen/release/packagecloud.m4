  packagecloud:
    if: needs.goreleaser.outputs.upload == 'true'
    needs:
      - smoke-tests
    runs-on: ubuntu-latest

    steps:
      - uses: actions/download-artifact@v2
        with:
          name: deb
          path: dist

      - uses: actions/download-artifact@v2
        with:
          name: rpm
          path: dist

      - name: Push to packagecloud
        id: pc-push
        uses: TykTechnologies/packagecloud-action@main
        env:
          PACKAGECLOUD_TOKEN: ${{ secrets.PACKAGECLOUD_TOKEN }}
        with:
          repo: tyk/${{ needs.goreleaser.outputs.pc }}
          dir: dist

      - name: Tell release channel
        if: always()
        run: |
          colour=bad
          pretext=":boom: Failed to push packages to ${{ needs.gorelease.outputs.pc }} for $${{ github.ref }}. Please review this run and correct it if needed."
          if [[ ${{ steps.pc-push.outcome }} == "success" ]]; then
              colour=good
              pretext="Please review the draft release at https://github.com/${{ github.repository }}/releases and delete if not required."
          fi

          curl https://raw.githubusercontent.com/rockymadden/slack-cli/master/src/slack -o /tmp/slack && chmod +x /tmp/slack
          /tmp/slack chat send \
          --actions '{"type": "button", "style": "primary", "text": "See log", "url": "https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}"}' \
          --author 'Bender' \
          --author-icon 'https://hcoop.net/~alephnull/bender/bender-arms.jpg' \
          --author-link 'https://github.com/TykTechnologies/tyk-ci' \
          --channel '#release' \
          --color $colour \
          --fields '{"title": "Repo", "value": "${{ needs.goreleaser.outputs.pc }}", "short": false}' \
          --footer 'github-actions' \
          --footer-icon 'https://assets-cdn.github.com/images/modules/logos_page/Octocat.png' \
          --image 'https://assets-cdn.github.com/images/modules/logos_page/Octocat.png' \
          --pretext "$pretext" \
          --text 'Commit message: ${{ github.event.head_commit.message }}' \
          --title 'New version ${{ needs.goreleaser.outputs.tag }} for ${{ needs.goreleaser.outputs.pc }}' \
          --title-link 'https://packagecloud.io/tyk/${{ needs.goreleaser.outputs.pc }}/'
