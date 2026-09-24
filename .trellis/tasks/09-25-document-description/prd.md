# 对接文档 description 字段

## Goal

对接后端文档固定头部新增的 description（front matter 派生列，server 0012）：DocumentRead/DocumentReadDetail/DocumentInResult 增加 description（非空、缺键兜底空串），详情固定头部 tags 下方展示，列表卡片副标题（可选），旧后端缺字段不 crash。

## Requirements

- TBD

## Acceptance Criteria

- [ ] TBD

## Notes

- Keep `prd.md` focused on requirements, constraints, and acceptance criteria.
- Lightweight tasks can remain PRD-only.
- For complex tasks, add `design.md` for technical design and `implement.md` for execution planning before `task.py start`.
