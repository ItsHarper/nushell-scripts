# As it goes, I changed my mind the morning after writing this, and went with option a.
# I had dismissed it without giving it enough thought (and the amount of writing dedicated
# to it here reflects that).

# Syncing all of the state and getting the downloaded files is done together intentionally.
# Consider the following:
#
# 1. Syncing the state requires looking up which files exist
#
# 2. The rest of the script needs the paths of the found files
#
# 3. If this function returned the full state for another function to filter out
#	the non-downloaded files, what does it do with the files that are not
#	downloaded?
#
#		a. It could specify the path of those files as null (gross, we want to make it impossible to represent invalid states)
#
#		b. It could not specify paths at all. Whatever code figures out the paths has just a few options:
#
#			i. Reconstruct the paths (which is an opportunity for bugs compared to getting them directly from ls)
#
#			ii. Query the filesystem again (slow, but probably not enough to matter compared to everything else)#
#
#			iii. Make this function return both takeoutState and a list of the paths of the downloaded files
#
#	Options a and b.i create opportunity for bugs. No way. We're aiming for as close to
#	bug-free as we can get in this program I'll use twice.
#
#	Option b.ii is fine from a maintainability perspective, but if there's any folder
#	that has a reasonable chance of having an unreasonable number of files in it, it's
#	the Downloads folder. Sure, the amount of time it takes to list the Downloads folder
#	again is almost certainly going to pale in comparison with the time it takes to do
#	the extractions, _but_ there's no guarantee that there's going to end up _being_ any
#	extractions!
#
#	Avoiding option b.ii could cut the amount of time it takes to run this program when
#	there's no new work to do by almost half in some cases, which for some
#	(almost certainly non-existent) users, might even be perceptible!
#
#	More seriously, I'm of the opinion that while premature optimization _can_ be bad,
# 	picking the slower of two similarly-complex options that have already occurred to
#	you is also bad. I spent at least an order of mangitude more time justifying this
#	decision for any would-be nitpickers than I did spent designing the software to be
#	fast.
#
#	Option b.iii might be _slightly_ slower than what I went with, but I'm more concerned
#	that it's much easier to misuse, as it requires the caller to figure out what it's
#	supposed to do to with two separate-but-related data structures. Also, the only real
#	downside I'm aware of to the actual design of this function is that it breaks the
#	"rule" of having functions do only one thing. I would much rather have a function
#	that is difficult to misuse but does more than one thing (for documented,
#	well-considered reasons), than a function that is easy to misuse.
